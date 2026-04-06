const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = process.env.PORT || 3000;

const MIME = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.svg': 'image/svg+xml'
};

const state = resetState();

const clients = new Map(); // playerId -> res (SSE)

function resetState() {
    return {
        mode: 'physical',
        hostId: null,
        players: [], // {id, name, role, totalScore, roundChange}
        settings: {},
        rounds: [], // {cards, trump, bids: {}, actuals: {}}
        currentRoundIdx: 0,
        phase: 'lobby', // lobby | bidding | playing | leaderboard | finished
        hands: {}, // current round hands keyed by playerId
        currentTrick: [], // [{playerId, card}]
        currentTurnPlayerId: null,
        leadPlayerId: null,
        trickNumber: 1
    };
}

function sendEvent(res, event, data) {
    res.write(`event: ${event}\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);
}

function broadcast(event, data) {
    for (const res of clients.values()) {
        sendEvent(res, event, data);
    }
}

function sanitizedState() {
    return {
        mode: state.mode,
        hostId: state.hostId,
        players: state.players,
        settings: state.settings,
        currentRoundIdx: state.currentRoundIdx,
        phase: state.phase,
        currentTrick: state.currentTrick,
        currentTurnPlayerId: state.currentTurnPlayerId,
        leadPlayerId: state.leadPlayerId,
        trickNumber: state.trickNumber,
        rounds: state.rounds.map(r => ({
            cards: r.cards,
            trump: r.trump,
            bids: r.bids,
            actuals: r.actuals
        }))
    };
}

function shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

function buildDeck() {
    const suits = ['♠️', '♥️', '♦️', '♣️'];
    const ranks = ['A','K','Q','J','10','9','8','7','6','5','4','3','2'];
    const deck = [];
    for (const s of suits) {
        for (const r of ranks) deck.push(`${r}${s}`);
    }
    return shuffle(deck);
}

function dealRound() {
    const round = state.rounds[state.currentRoundIdx];
    const cardsNeeded = round.cards * state.players.length;
    const deck = buildDeck();
    if (cardsNeeded > deck.length) {
        state.phase = 'lobby';
        return { error: `Not enough cards for ${state.players.length} players x ${round.cards} cards.` };
    }
    state.hands = {};
    for (const p of state.players) {
        p.roundChange = 0;
        state.hands[p.id] = deck.splice(0, round.cards);
    }
    state.currentTrick = [];
    state.trickNumber = 1;
    const firstIdx = state.currentRoundIdx % state.players.length;
    state.leadPlayerId = state.players[firstIdx].id;
    state.currentTurnPlayerId = state.leadPlayerId;
    // clear bids/actuals for this round
    round.bids = {};
    round.actuals = {};
    return { ok: true };
}

function calculateScores() {
    const round = state.rounds[state.currentRoundIdx];
    for (const p of state.players) {
        const bid = round.bids[p.id] || 0;
        const actual = round.actuals[p.id] || 0;
        let points = 0;
        if (bid === actual) {
            points = 10 + actual;
        } else if (actual > bid) {
            points = state.settings.lenientOvertrick ? (10 + actual) : -10;
        } else {
            points = -10 * bid;
        }
        p.roundChange = points;
        p.totalScore = (p.totalScore || 0) + points;
    }
}

async function readBody(req) {
    return new Promise((resolve, reject) => {
        let data = '';
        req.on('data', chunk => {
            data += chunk;
            if (data.length > 1e6) {
                req.connection.destroy();
                reject(new Error('Payload too large'));
            }
        });
        req.on('end', () => {
            try {
                resolve(data ? JSON.parse(data) : {});
            } catch (e) {
                reject(e);
            }
        });
    });
}

function serveStatic(req, res) {
    const urlPath = req.url.split('?')[0];
    let filePath = path.join(__dirname, urlPath === '/' ? '/index.html' : urlPath);
    if (!filePath.startsWith(__dirname)) {
        res.writeHead(403); res.end('Forbidden'); return;
    }
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404); res.end('Not found'); return;
        }
        const ext = path.extname(filePath);
        res.writeHead(200, { 'Content-Type': MIME[ext] || 'text/plain' });
        res.end(data);
    });
}

function pathOnly(req) {
    return req.url.split('?')[0].replace(/\/+$/, '') || '/';
}

function json(res, code, obj) {
    res.writeHead(code, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
    res.end(JSON.stringify(obj));
}

const server = http.createServer(async (req, res) => {
    const path = pathOnly(req);

    if (req.method === 'GET' && req.url.startsWith('/events')) {
        const params = new URLSearchParams(req.url.split('?')[1]);
        const pid = params.get('playerId');
        res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'Access-Control-Allow-Origin': '*'
        });
        res.write('\n');
        if (pid) {
            clients.set(pid, res);
            sendEvent(res, 'state', sanitizedState());
            const hand = state.hands[pid];
            if (hand) sendEvent(res, 'hand', { hand, round: state.currentRoundIdx });
            req.on('close', () => clients.delete(pid));
        } else {
            sendEvent(res, 'error', { message: 'Missing playerId' });
            res.end();
        }
        return;
    }

    if (req.method === 'OPTIONS') {
        res.writeHead(204, {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        });
        res.end();
        return;
    }

    // health
    if (req.method === 'GET' && path === '/health') {
        return json(res, 200, { ok: true, phase: state.phase, players: state.players.length });
    }

    if (req.method === 'POST' && path === '/api/register') {
        try {
            const body = await readBody(req);
            const { name, role, playerId: reuseId } = body;
            if (!name) { res.writeHead(400); return res.end('Name required'); }
            if (role === 'host' && state.hostId && state.hostId !== body.playerId) {
                res.writeHead(400); return res.end('Host already set');
            }
            // Reuse existing player if provided
            let player = reuseId ? state.players.find(p => p.id === reuseId) : null;
            if (player) {
                player.name = name;
                if (role) player.role = role;
            } else {
                const id = crypto.randomUUID();
                player = { id, name, role: role || 'player', totalScore: 0, roundChange: 0 };
                state.players.push(player);
            }
            if (!state.hostId && player.role === 'host') state.hostId = player.id;
            res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
            res.end(JSON.stringify({ playerId: player.id, role: player.role, hostId: state.hostId }));
            broadcast('state', sanitizedState());
        } catch (e) {
            res.writeHead(500); res.end('Invalid JSON');
        }
        return;
    }

    if (req.method === 'POST' && path === '/api/leave') {
        try {
            const body = await readBody(req);
            const { playerId } = body;
            if (!playerId) { res.writeHead(400); return res.end('playerId required'); }
            const idx = state.players.findIndex(p => p.id === playerId);
            if (idx === -1) { res.writeHead(200); return res.end('OK'); }
            state.players.splice(idx, 1);
            delete state.hands[playerId];
            if (state.hostId === playerId) state.hostId = null;
            // remove bids/actuals references
            const round = state.rounds[state.currentRoundIdx];
            if (round) {
                delete round.bids[playerId];
                delete round.actuals[playerId];
            }
            const client = clients.get(playerId);
            if (client) {
                clients.delete(playerId);
                try { client.end(); } catch (_) {}
            }
            // if no players left, reset everything
            if (state.players.length === 0) {
                const newState = resetState();
                Object.keys(state).forEach(k => delete state[k]);
                Object.assign(state, newState);
            }
            broadcast('state', sanitizedState());
            return json(res, 200, { ok: true });
        } catch (e) { res.writeHead(500); res.end('Invalid JSON'); }
        return;
    }

    if (req.method === 'POST' && path === '/api/kick') {
        try {
            const body = await readBody(req);
            const { playerId, targetId } = body;
            if (!playerId || !targetId) { res.writeHead(400); return res.end('playerId and targetId required'); }
            if (state.hostId && playerId !== state.hostId) {
                res.writeHead(403); return res.end('Only host can kick');
            }
            if (playerId === targetId) { res.writeHead(400); return res.end('Use leave to remove yourself'); }
            const idx = state.players.findIndex(p => p.id === targetId);
            if (idx === -1) { res.writeHead(200); return res.end('OK'); }
            state.players.splice(idx, 1);
            delete state.hands[targetId];
            const round = state.rounds[state.currentRoundIdx];
            if (round) {
                delete round.bids[targetId];
                delete round.actuals[targetId];
            }
            const client = clients.get(targetId);
            if (client) { clients.delete(targetId); try { client.end(); } catch (_) {} }
            broadcast('state', sanitizedState());
            return json(res, 200, { ok: true });
        } catch (e) { res.writeHead(500); res.end('Invalid JSON'); }
        return;
    }

    if (req.method === 'POST' && path === '/api/reset') {
        try {
            const body = await readBody(req);
            const { playerId } = body;
            if (state.hostId && playerId !== state.hostId) {
                res.writeHead(403); return res.end('Only host can reset');
            }
            // Note: we keep existing SSE connections; they will see empty lobby state.
            const newState = resetState();
            Object.keys(state).forEach(k => delete state[k]);
            Object.assign(state, newState);
            broadcast('state', sanitizedState());
            return json(res, 200, { ok: true });
        } catch (e) { res.writeHead(500); res.end('Invalid JSON'); }
        return;
    }

    if (req.method === 'POST' && path === '/api/start') {
        try {
            const body = await readBody(req);
            const { playerId, settings, mode } = body;
            if (state.hostId && playerId !== state.hostId) {
                res.writeHead(403); return res.end('Only host can start');
            }
            state.mode = mode || 'virtual';
            state.settings = settings || {};
            const cardsSequence = [];
            const startCards = parseInt(settings.startingCards) || 10;
            const roundStyle = settings.roundStyle || 'countdown';
            if (roundStyle === 'countdown') {
                for (let c = startCards; c >= 1; c--) cardsSequence.push(c);
            } else {
                for (let i = 0; i < startCards; i++) cardsSequence.push(startCards);
            }
            state.rounds = cardsSequence.map(cards => ({
                cards,
                trump: ['♠️','♥️','♦️','♣️'][Math.floor(Math.random()*4)],
                bids: {},
                actuals: {}
            }));
            state.currentRoundIdx = 0;
            state.phase = 'bidding';
            const dealResult = dealRound();
            if (dealResult.error) {
                res.writeHead(400); res.end(dealResult.error); return;
            }
            res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
            res.end(JSON.stringify({ ok: true }));
            broadcast('state', sanitizedState());
            // send private hands
            for (const [pid, hand] of Object.entries(state.hands)) {
                const client = clients.get(pid);
                if (client) sendEvent(client, 'hand', { hand, round: state.currentRoundIdx });
            }
        } catch (e) {
            res.writeHead(500); res.end('Invalid JSON');
        }
        return;
    }

    if (req.method === 'POST' && path === '/api/bid') {
        try {
            const body = await readBody(req);
            const { playerId, bid } = body;
            const round = state.rounds[state.currentRoundIdx];
            if (!round) { res.writeHead(400); return res.end('No active round'); }
            round.bids[playerId] = parseInt(bid) || 0;
            res.writeHead(200, { 'Access-Control-Allow-Origin': '*' }); res.end('OK');
            const allSubmitted = Object.keys(round.bids).length === state.players.length;
            if (allSubmitted) {
                state.phase = 'playing';
                state.currentTrick = [];
                state.trickNumber = 1;
                const firstIdx = state.currentRoundIdx % state.players.length;
                state.leadPlayerId = state.players[firstIdx].id;
                state.currentTurnPlayerId = state.leadPlayerId;
            }
            broadcast('state', sanitizedState());
        } catch (e) { res.writeHead(500); res.end('Invalid JSON'); }
        return;
    }

    if (req.method === 'POST' && path === '/api/actual') {
        try {
            const body = await readBody(req);
            const { playerId, actual } = body;
            const round = state.rounds[state.currentRoundIdx];
            if (!round) { res.writeHead(400); return res.end('No active round'); }
            round.actuals[playerId] = parseInt(actual) || 0;
            res.writeHead(200, { 'Access-Control-Allow-Origin': '*' }); res.end('OK');
            const allSubmitted = Object.keys(round.actuals).length === state.players.length;
            if (allSubmitted) {
                calculateScores();
                state.phase = (state.currentRoundIdx >= state.rounds.length -1) ? 'finished' : 'leaderboard';
                broadcast('state', sanitizedState());
            } else {
                broadcast('state', sanitizedState());
            }
        } catch (e) { res.writeHead(500); res.end('Invalid JSON'); }
        return;
    }

    if (req.method === 'POST' && path === '/api/next-round') {
        try {
            const body = await readBody(req);
            const { playerId } = body;
            if (state.hostId && playerId !== state.hostId) {
                res.writeHead(403); return res.end('Only host can advance rounds');
            }
            if (state.currentRoundIdx >= state.rounds.length - 1) {
                state.phase = 'finished';
                broadcast('state', sanitizedState());
                res.writeHead(200, { 'Access-Control-Allow-Origin': '*' }); return res.end('Finished');
            }
            state.currentRoundIdx++;
            state.phase = 'bidding';
            const dealResult = dealRound();
            if (dealResult.error) {
                state.phase = 'finished';
                res.writeHead(400); return res.end(dealResult.error);
            }
            res.writeHead(200, { 'Access-Control-Allow-Origin': '*' }); res.end('OK');
            broadcast('state', sanitizedState());
            for (const [pid, hand] of Object.entries(state.hands)) {
                const client = clients.get(pid);
                if (client) sendEvent(client, 'hand', { hand, round: state.currentRoundIdx });
            }
        } catch (e) { res.writeHead(500); res.end('Invalid JSON'); }
        return;
    }

    if (req.method === 'POST' && path === '/api/play-card') {
        try {
            const body = await readBody(req);
            const { playerId, card } = body;
            if (state.phase !== 'playing') { res.writeHead(400); return res.end('Not in playing phase'); }
            if (playerId !== state.currentTurnPlayerId) { res.writeHead(400); return res.end('Not your turn'); }
            const hand = state.hands[playerId] || [];
            const cardIdx = hand.indexOf(card);
            if (cardIdx === -1) { res.writeHead(400); return res.end('Card not in hand'); }

            const round = state.rounds[state.currentRoundIdx];
            const leadSuit = state.currentTrick[0] ? suitOf(state.currentTrick[0].card) : null;
            const playingSuit = suitOf(card);
            if (leadSuit) {
                const hasLead = hand.some(c => suitOf(c) === leadSuit);
                if (hasLead && playingSuit !== leadSuit) {
                    res.writeHead(400); return res.end('Must follow suit');
                }
            }

            // play card
            hand.splice(cardIdx, 1);
            state.currentTrick.push({ playerId, card });

            // determine next turn
            const currentIdx = state.players.findIndex(p => p.id === playerId);
            const nextIdx = (currentIdx + 1) % state.players.length;
            state.currentTurnPlayerId = state.players[nextIdx].id;

            // if trick complete
            if (state.currentTrick.length === state.players.length) {
                const winnerId = decideTrickWinner(state.currentTrick, round.trump);
                round.actuals[winnerId] = (round.actuals[winnerId] || 0) + 1;
                state.currentTrick = [];
                state.trickNumber += 1;
                state.currentTurnPlayerId = winnerId;
                state.leadPlayerId = winnerId;

                const cardsLeft = hand.length; // all hands same size now
                if (cardsLeft === 0) {
                    calculateScores();
                    state.phase = (state.currentRoundIdx >= state.rounds.length -1) ? 'finished' : 'leaderboard';
                }
            }

            res.writeHead(200, { 'Access-Control-Allow-Origin': '*' }); res.end('OK');
            broadcast('state', sanitizedState());
            // refresh hand for player
            const client = clients.get(playerId);
            if (client) sendEvent(client, 'hand', { hand: state.hands[playerId], round: state.currentRoundIdx });
        } catch (e) { res.writeHead(500); res.end('Invalid JSON'); }
        return;
    }

    if (req.method === 'POST') {
        return json(res, 404, { error: 'Unknown POST path', path });
    }

    serveStatic(req, res);
});

const HOST = '0.0.0.0';

server.listen(PORT, HOST, () => {
    console.log(`Kaat LAN server running on http://${HOST}:${PORT}`);
});

function suitOf(card) {
    const match = card.match(/[♠♥♦♣]/);
    return match ? match[0] : '';
}

const rankMap = {
    'A': 13, 'K': 12, 'Q': 11, 'J': 10,
    '10': 9, '9': 8, '8': 7, '7': 6, '6': 5, '5': 4, '4': 3, '3': 2, '2': 1
};

function rankOf(card) {
    if (card.startsWith('10')) return rankMap['10'];
    const r = card[0];
    return rankMap[r] || 0;
}

function decideTrickWinner(trick, trump) {
    if (!trick.length) return null;
    const leadSuit = suitOf(trick[0].card);
    let best = trick[0];
    for (const play of trick.slice(1)) {
        const suit = suitOf(play.card);
        const isTrump = suit === trump;
        const bestIsTrump = suitOf(best.card) === trump;
        if (isTrump && !bestIsTrump) { best = play; continue; }
        if (!isTrump && bestIsTrump) continue;
        // same suit (either both trump or both lead)
        if (suit === suitOf(best.card) && rankOf(play.card) > rankOf(best.card)) {
            best = play;
        } else if (suit === leadSuit && suitOf(best.card) !== trump && suitOf(best.card) !== leadSuit) {
            best = play;
        }
    }
    return best.playerId;
}
