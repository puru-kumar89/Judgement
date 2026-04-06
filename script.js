// Modes and state
let mode = 'physical';

const localState = {
    settings: { lenientOvertrick: false, successMultiplier: 10, penaltyMultiplier: 10, overtrickBonus: 1, startingCards: 10, maxRounds: 0 },
    players: [],
    rounds: [],
    currentRoundIdx: 0,
    suits: ['♠️', '♥️', '♦️', '♣️']
};

let remoteState = null;
let playerId = null;
let role = 'player';
let eventSource = null;
let myHand = [];

// DOM Elements
const views = {
    setup: document.getElementById('setup-view'),
    bidding: document.getElementById('bidding-view'),
    results: document.getElementById('results-view'),
    leaderboard: document.getElementById('leaderboard-view'),
    table: document.getElementById('table-view')
};

function switchView(viewName) {
    Object.values(views).forEach(v => v.classList.remove('active'));
    views[viewName].classList.add('active');
}

// Event listeners
const modeRadios = document.querySelectorAll('input[name="game-mode"]');
modeRadios.forEach(r => r.addEventListener('change', handleModeChange));

document.getElementById('start-game-btn').addEventListener('click', startGame);
document.getElementById('submit-bids-btn').addEventListener('click', submitBids);
document.getElementById('calculate-scores-btn').addEventListener('click', submitActuals);
document.getElementById('next-round-btn').addEventListener('click', nextRound);
document.getElementById('join-lobby-btn').addEventListener('click', joinLobby);
document.getElementById('back-to-setup-btn').addEventListener('click', () => switchView('setup'));
document.getElementById('back-to-bids-btn').addEventListener('click', () => switchView('bidding'));
document.getElementById('back-to-results-btn').addEventListener('click', () => switchView('results'));
document.getElementById('score-preset').addEventListener('change', handlePresetChange);
document.getElementById('lenient-overtrick-toggle').addEventListener('change', handlePresetToggleSync);

document.getElementById('add-player-btn').addEventListener('click', () => {
    const container = document.getElementById('player-inputs');
    const inputCount = container.querySelectorAll('input').length + 1;
    const input = document.createElement('input');
    input.type = 'text';
    input.className = 'player-name-input glass-input';
    input.placeholder = `Player ${inputCount}`;
    container.appendChild(input);
});

function handleModeChange() {
    mode = document.querySelector('input[name="game-mode"]:checked').value;
    const physicalBlock = document.getElementById('physical-players');
    const virtualBlock = document.getElementById('virtual-panel');
    if (mode === 'physical') {
        physicalBlock.style.display = 'block';
        virtualBlock.style.display = 'none';
        document.getElementById('submit-bids-btn').innerText = 'Start Playing';
        document.getElementById('calculate-scores-btn').innerText = 'Calculate Scores';
        document.getElementById('next-round-btn').innerText = 'Next Round';
    } else {
        physicalBlock.style.display = 'none';
        virtualBlock.style.display = 'block';
        document.getElementById('submit-bids-btn').innerText = 'Submit My Bid';
        document.getElementById('calculate-scores-btn').innerText = 'Submit My Tricks';
        document.getElementById('next-round-btn').innerText = 'Next Round (Host)';
    }
}

function handlePresetChange() {
    const preset = document.getElementById('score-preset').value;
    const customPanel = document.getElementById('custom-scoring');
    if (preset === 'standard') {
        setScoringInputs({ success: 10, penalty: 10, bonus: 1, lenient: true });
        customPanel.style.display = 'none';
    } else if (preset === 'strict') {
        setScoringInputs({ success: 10, penalty: 10, bonus: 0, lenient: false });
        customPanel.style.display = 'none';
    } else {
        customPanel.style.display = 'grid';
    }
}

function handlePresetToggleSync() {
    const preset = document.getElementById('score-preset').value;
    if (preset !== 'custom') {
        // Move to custom if user changes lenient while on a preset.
        document.getElementById('score-preset').value = 'custom';
        document.getElementById('custom-scoring').style.display = 'grid';
    }
}

function setScoringInputs({ success, penalty, bonus, lenient }) {
    document.getElementById('score-success-mult').value = success;
    document.getElementById('score-penalty-mult').value = penalty;
    document.getElementById('score-overtrick-bonus').value = bonus;
    document.getElementById('lenient-overtrick-toggle').checked = lenient;
}

async function startGame() {
    mode = document.querySelector('input[name="game-mode"]:checked').value;
    if (mode === 'physical') {
        handlePresetChange(); // ensure presets apply before reading values
        startGamePhysical();
        return;
    }

    if (!playerId) {
        alert('Join the virtual lobby first.');
        return;
    }
    if (role !== 'host') {
        alert('Only the host can start the virtual game.');
        return;
    }

    handlePresetChange(); // ensure preset values applied
    const settings = {
        lenientOvertrick: document.getElementById('lenient-overtrick-toggle').checked,
        successMultiplier: parseInt(document.getElementById('score-success-mult').value) || 10,
        penaltyMultiplier: parseInt(document.getElementById('score-penalty-mult').value) || 10,
        overtrickBonus: parseInt(document.getElementById('score-overtrick-bonus').value) || 1,
        startingCards: parseInt(document.getElementById('starting-cards').value) || 10,
        roundStyle: document.getElementById('round-style').value
    };

    try {
        await postJSON('/api/start', { playerId, settings, mode: 'virtual' });
        document.getElementById('virtual-status').innerText = 'Game started. Dealing cards...';
    } catch (err) {
        alert('Unable to start virtual game: ' + err.message);
    }
}

// -------------------
// Physical mode logic
// -------------------
function startGamePhysical() {
    localState.settings.lenientOvertrick = document.getElementById('lenient-overtrick-toggle').checked;
    localState.settings.successMultiplier = parseInt(document.getElementById('score-success-mult').value) || 10;
    localState.settings.penaltyMultiplier = parseInt(document.getElementById('score-penalty-mult').value) || 10;
    localState.settings.overtrickBonus = parseInt(document.getElementById('score-overtrick-bonus').value) || 1;
    localState.settings.startingCards = parseInt(document.getElementById('starting-cards').value) || 10;

    const inputs = document.querySelectorAll('.player-name-input');
    localState.players = Array.from(inputs)
        .map(input => input.value.trim())
        .filter(val => val !== '')
        .map(name => ({ name, totalScore: 0, roundChange: 0 }));

    if (localState.players.length < 3) {
        alert('Please enter at least 3 players.');
        return;
    }

    const roundStyle = document.getElementById('round-style').value;
    const cardsSequence = [];
    if (roundStyle === 'countdown') {
        for (let c = localState.settings.startingCards; c >= 1; c--) cardsSequence.push(c);
    } else {
        for (let c = 0; c < localState.settings.startingCards; c++) cardsSequence.push(localState.settings.startingCards);
    }
    localState.settings.maxRounds = cardsSequence.length;

    localState.rounds = cardsSequence.map(cards => ({
        cards,
        trump: localState.suits[Math.floor(Math.random() * localState.suits.length)],
        bids: Array(localState.players.length).fill(0),
        actuals: Array(localState.players.length).fill(0)
    }));

    localState.currentRoundIdx = 0;
    renderRoundPhysical();
}

function renderRoundPhysical() {
    const round = localState.rounds[localState.currentRoundIdx];
    document.getElementById('hand-container').style.display = 'none';

    document.getElementById('bid-round-number').innerText = `${localState.currentRoundIdx + 1} / ${localState.settings.maxRounds}`;
    document.getElementById('bid-cards-count').innerText = round.cards;
    document.getElementById('bid-trump-suit').innerText = round.trump;

    const biddingContainer = document.getElementById('bidding-inputs');
    biddingContainer.innerHTML = '';
    const firstPlayerIdx = localState.currentRoundIdx % localState.players.length;

    for (let i = 0; i < localState.players.length; i++) {
        const pIdx = (firstPlayerIdx + i) % localState.players.length;
        const row = document.createElement('div');
        row.className = 'player-input-row';
        row.innerHTML = `
            <span class="name">${localState.players[pIdx].name} ${i === localState.players.length -1 ? '(Dealer)' : ''}</span>
            <input type="number" min="0" max="${round.cards}" data-pindex="${pIdx}" class="bid-input" value="${round.bids[pIdx]}">
        `;
        biddingContainer.appendChild(row);
    }

    document.querySelectorAll('.bid-input').forEach(input => {
        input.addEventListener('input', () => checkHookWarning(round.cards));
    });
    checkHookWarning(round.cards);
    switchView('bidding');
}

function submitBidsPhysical() {
    const round = localState.rounds[localState.currentRoundIdx];
    const inputs = document.querySelectorAll('.bid-input');
    inputs.forEach(input => {
        const pIdx = parseInt(input.getAttribute('data-pindex'));
        round.bids[pIdx] = parseInt(input.value) || 0;
    });
    renderResultsPhysical();
}

function renderResultsPhysical() {
    const round = localState.rounds[localState.currentRoundIdx];
    document.getElementById('res-round-number').innerText = localState.currentRoundIdx + 1;
    document.getElementById('res-cards-count').innerText = round.cards;
    document.getElementById('res-trump-suit').innerText = round.trump;
    document.getElementById('total-tricks-expected').innerText = round.cards;

    const resultsContainer = document.getElementById('results-inputs');
    resultsContainer.innerHTML = '';
    for (let i = 0; i < localState.players.length; i++) {
        const row = document.createElement('div');
        row.className = 'player-input-row';
        row.innerHTML = `
            <span class="name">${localState.players[i].name} <span style="font-size:0.8rem;color:var(--accent)">(Bid: ${round.bids[i]})</span></span>
            <input type="number" min="0" max="${round.cards}" data-pindex="${i}" class="actual-input" value="${round.actuals[i] || 0}">
        `;
        resultsContainer.appendChild(row);
    }

    document.querySelectorAll('.actual-input').forEach(input => {
        input.addEventListener('input', () => updateResultsTracker(round.cards));
    });
    updateResultsTracker(round.cards);
    switchView('results');
}

function updateResultsTracker(expected) {
    const inputs = Array.from(document.querySelectorAll('.actual-input'));
    const totalActuals = inputs.reduce((sum, input) => sum + (parseInt(input.value) || 0), 0);
    document.getElementById('tricks-accounted').innerText = totalActuals;
    const trackerBar = document.querySelector('.results-tracker-bar');
    trackerBar.classList.remove('error', 'success');
    if (totalActuals !== expected) trackerBar.classList.add('error');
    else trackerBar.classList.add('success');
}

function calculateScoresPhysical() {
    const round = localState.rounds[localState.currentRoundIdx];
    const inputs = document.querySelectorAll('.actual-input');
    let totalActuals = 0;
    inputs.forEach(input => {
        const pIdx = parseInt(input.getAttribute('data-pindex'));
        const val = parseInt(input.value) || 0;
        round.actuals[pIdx] = val;
        totalActuals += val;
    });
    if (totalActuals !== round.cards) {
        alert(`Error: The total number of tricks won (${totalActuals}) must equal the number of cards dealt (${round.cards}). Please verify.`);
        return;
    }

    const { lenientOvertrick, successMultiplier, penaltyMultiplier, overtrickBonus } = localState.settings;
    for (let i = 0; i < localState.players.length; i++) {
        const bid = round.bids[i];
        const actual = round.actuals[i];
        let points = 0;

        if (bid === actual) {
            // Exact bid: bid * multiplier (e.g., bid 3 -> 30 when multiplier is 10)
            points = bid * successMultiplier;
        } else if (actual > bid) {
            // Overtrick
            if (lenientOvertrick) {
                // Base for bid + small bonus per extra trick
                points = bid * successMultiplier + (actual - bid) * overtrickBonus;
            } else {
                // Strict: penalize against the original bid size
                points = -bid * penaltyMultiplier;
            }
        } else {
            // Undertrick: penalize against the original bid size
            points = -bid * penaltyMultiplier;
        }

        localState.players[i].roundChange = points;
        localState.players[i].totalScore += points;
    }
    renderLeaderboardPhysical();
}

function renderLeaderboardPhysical() {
    document.getElementById('lb-round-number').innerText = localState.currentRoundIdx + 1;
    const container = document.getElementById('leaderboard-container');
    container.innerHTML = '';
    const sortedPlayers = [...localState.players].sort((a, b) => b.totalScore - a.totalScore);
    sortedPlayers.forEach((player, idx) => {
        const changeClass = player.roundChange > 0 ? 'score-up' : (player.roundChange < 0 ? 'score-down' : 'score-zero');
        const sign = player.roundChange > 0 ? '+' : '';
        const card = document.createElement('div');
        card.className = `lb-card ${idx === 0 ? 'rank-1' : ''}`;
        card.innerHTML = `
            <div class="lb-rank">#${idx + 1}</div>
            <div class="lb-details">
                <div class="lb-name">${player.name}</div>
                <div class="lb-score-change ${changeClass}">${sign}${player.roundChange} this round</div>
            </div>
            <div class="lb-total">${player.totalScore}</div>
        `;
        container.appendChild(card);
    });
    if (localState.currentRoundIdx >= localState.settings.maxRounds - 1) {
        document.getElementById('next-round-btn').innerText = 'Finish Game';
    }
    switchView('leaderboard');
}

function nextRoundPhysical() {
    if (localState.currentRoundIdx >= localState.settings.maxRounds - 1) {
        alert('Game Over! Refresh to start a new game.');
        return;
    }
    localState.currentRoundIdx++;
    renderRoundPhysical();
}

// -------------------
// Virtual mode helpers
// -------------------
async function joinLobby() {
    const name = document.getElementById('virtual-name').value.trim();
    const hosting = document.getElementById('virtual-host-toggle').checked;
    if (!name) { alert('Enter your name first.'); return; }
    try {
        const res = await postJSON('/api/register', { name, role: hosting ? 'host' : 'player', playerId });
        playerId = res.playerId;
        role = res.role;
        document.getElementById('virtual-status').innerText = `Connected as ${name} (${role}).`;
        connectEvents();
    } catch (err) {
        alert('Join failed: ' + err.message);
    }
}

function connectEvents() {
    if (!playerId) return;
    if (eventSource) eventSource.close();
    eventSource = new EventSource(`/events?playerId=${playerId}`);
    eventSource.addEventListener('state', (e) => {
        remoteState = JSON.parse(e.data);
        renderFromRemote();
    });
    eventSource.addEventListener('hand', (e) => {
        const data = JSON.parse(e.data);
        if (data.hand) {
            myHand = data.hand;
            renderHand();
        }
    });
    eventSource.onerror = () => {
        document.getElementById('virtual-status').innerText = 'Disconnected. Retrying...';
    };
}

function renderHand() {
    const container = document.getElementById('hand-container');
    const list = document.getElementById('hand-cards');
    if (!myHand || myHand.length === 0) {
        container.style.display = 'none';
        list.innerHTML = '';
        return;
    }
    container.style.display = 'block';
    list.innerHTML = '';
    myHand.forEach(card => {
        const span = document.createElement('span');
        span.className = 'hand-card';
        span.innerText = card;
        list.appendChild(span);
    });
}

function renderLobbyList(players) {
    const list = document.getElementById('lobby-list');
    list.innerHTML = '';
    players.forEach(p => {
        const li = document.createElement('li');
        const hostTag = p.id === remoteState?.hostId ? ' (Host)' : '';
        li.innerText = `${p.name}${hostTag}`;
        list.appendChild(li);
    });
}

function renderFromRemote() {
    if (!remoteState) return;
    renderLobbyList(remoteState.players || []);

    const round = remoteState.rounds?.[remoteState.currentRoundIdx];
    const totalRounds = remoteState.rounds?.length || 0;

    if (!round || remoteState.phase === 'lobby') {
        switchView('setup');
        return;
    }

    document.getElementById('bid-round-number').innerText = `${remoteState.currentRoundIdx + 1} / ${totalRounds}`;
    document.getElementById('bid-cards-count').innerText = round.cards;
    document.getElementById('bid-trump-suit').innerText = round.trump;
    document.getElementById('res-round-number').innerText = remoteState.currentRoundIdx + 1;
    document.getElementById('res-cards-count').innerText = round.cards;
    document.getElementById('res-trump-suit').innerText = round.trump;
    document.getElementById('total-tricks-expected').innerText = round.cards;

    const bidsDone = Object.keys(round.bids || {}).length === (remoteState.players?.length || 0);
    const actualsDone = Object.keys(round.actuals || {}).length === (remoteState.players?.length || 0);

    if (remoteState.phase === 'leaderboard' || remoteState.phase === 'finished') {
        renderLeaderboardVirtual();
        return;
    }

    if (remoteState.phase === 'playing') {
        renderTableVirtual(round);
        return;
    }

    if (bidsDone) {
        renderResultsVirtual(round);
    } else {
        renderBiddingVirtual(round);
    }
}

function renderBiddingVirtual(round) {
    const container = document.getElementById('bidding-inputs');
    container.innerHTML = '';
    const players = remoteState.players || [];
    const firstIdx = (remoteState.currentRoundIdx || 0) % players.length;
    players.forEach((_, i) => {
        const p = players[(firstIdx + i) % players.length];
        const val = round.bids?.[p.id] ?? '';
        const row = document.createElement('div');
        row.className = 'player-input-row';
        const dealerTag = i === players.length -1 ? '(Dealer)' : '';
        row.innerHTML = `
            <span class="name">${p.name} ${dealerTag}</span>
            <input type="number" min="0" max="${round.cards}" data-pid="${p.id}" class="bid-input" value="${val}" ${p.id === playerId ? '' : 'disabled'}>
        `;
        container.appendChild(row);
    });

    document.querySelectorAll('.bid-input').forEach(input => {
        input.addEventListener('input', () => checkHookWarning(round.cards));
    });
    checkHookWarning(round.cards);
    renderHand();
    switchView('bidding');
}

function renderResultsVirtual(round) {
    const container = document.getElementById('results-inputs');
    container.innerHTML = '';
    const players = remoteState.players || [];
    players.forEach(p => {
        const actualVal = round.actuals?.[p.id] ?? '';
        const bidVal = round.bids?.[p.id] ?? 0;
        const row = document.createElement('div');
        row.className = 'player-input-row';
        row.innerHTML = `
            <span class="name">${p.name} <span style="font-size:0.8rem;color:var(--accent)">(Bid: ${bidVal})</span></span>
            <input type="number" min="0" max="${round.cards}" data-pid="${p.id}" class="actual-input" value="${actualVal}" ${p.id === playerId ? '' : 'disabled'}>
        `;
        container.appendChild(row);
    });
    document.querySelectorAll('.actual-input').forEach(input => {
        input.addEventListener('input', () => updateResultsTracker(round.cards));
    });
    updateResultsTracker(round.cards);
    renderHand();
    switchView('results');
}

function renderLeaderboardVirtual() {
    const container = document.getElementById('leaderboard-container');
    container.innerHTML = '';
    const players = [...(remoteState.players || [])].sort((a, b) => (b.totalScore || 0) - (a.totalScore || 0));
    players.forEach((p, idx) => {
        const changeClass = p.roundChange > 0 ? 'score-up' : (p.roundChange < 0 ? 'score-down' : 'score-zero');
        const sign = p.roundChange > 0 ? '+' : '';
        const card = document.createElement('div');
        card.className = `lb-card ${idx === 0 ? 'rank-1' : ''}`;
        card.innerHTML = `
            <div class="lb-rank">#${idx + 1}</div>
            <div class="lb-details">
                <div class="lb-name">${p.name}</div>
                <div class="lb-score-change ${changeClass}">${sign}${p.roundChange || 0} this round</div>
            </div>
            <div class="lb-total">${p.totalScore || 0}</div>
        `;
        container.appendChild(card);
    });
    switchView('leaderboard');
}

function renderTableVirtual(round) {
    document.getElementById('table-trick-number').innerText = remoteState.trickNumber || 1;
    document.getElementById('table-round-number').innerText = remoteState.currentRoundIdx + 1;
    document.getElementById('table-trump').innerText = round.trump;
    const turnPlayer = remoteState.players?.find(p => p.id === remoteState.currentTurnPlayerId);
    document.getElementById('table-turn').innerText = turnPlayer ? turnPlayer.name : '-';

    // bids overview
    const bidsWrap = document.getElementById('table-bids');
    bidsWrap.innerHTML = '';
    (remoteState.players || []).forEach(p => {
        const bid = round.bids?.[p.id] ?? 0;
        const actual = round.actuals?.[p.id] ?? 0;
        const div = document.createElement('div');
        div.className = 'table-bid-pill';
        div.innerHTML = `<span>${p.name}</span><span>${actual}/${bid}</span>`;
        bidsWrap.appendChild(div);
    });

    // seats
    const seats = document.getElementById('table-players');
    seats.innerHTML = '';
    (remoteState.players || []).forEach(p => {
        const seat = document.createElement('div');
        seat.className = 'table-seat' + (p.id === remoteState.currentTurnPlayerId ? ' turn' : '');
        const trickCard = (remoteState.currentTrick || []).find(t => t.playerId === p.id);
        const bid = round.bids?.[p.id] ?? 0;
        const actual = round.actuals?.[p.id] ?? 0;
        seat.innerHTML = `
            <div class="seat-name">${p.name}${p.id === remoteState.hostId ? ' ⭐' : ''}</div>
            <div class="seat-score">Score: ${p.totalScore || 0}</div>
            <div class="seat-actuals">Tricks: ${actual}/${bid}</div>
            ${trickCard ? `<div class="played-card">${trickCard.card}</div>` : ''}
        `;
        seats.appendChild(seat);
    });

    // current trick pile
    const trickBox = document.getElementById('current-trick');
    trickBox.innerHTML = '';
    (remoteState.currentTrick || []).forEach(play => {
        const player = remoteState.players.find(p => p.id === play.playerId);
        const div = document.createElement('div');
        div.className = 'trick-card';
        div.innerText = `${player ? player.name + ': ' : ''}${play.card}`;
        trickBox.appendChild(div);
    });

    // hand to play
    const handWrap = document.getElementById('play-hand');
    handWrap.innerHTML = '';
    const myTurn = remoteState.currentTurnPlayerId === playerId;
    handWrap.classList.toggle('playable', myTurn);
    myHand.forEach(card => {
        const span = document.createElement('span');
        span.className = 'hand-card';
        span.innerText = card;
        if (myTurn) {
            span.addEventListener('click', () => playCard(card));
        }
        handWrap.appendChild(span);
    });
    const status = document.getElementById('play-status');
    status.innerText = myTurn ? 'Your turn: tap a card to play' : `Waiting for ${turnPlayer ? turnPlayer.name : 'other players'}...`;

    renderHand();
    switchView('table');
}

function submitBidsVirtual() {
    const myInput = document.querySelector('.bid-input[data-pid="' + playerId + '"]');
    if (!myInput) { alert('You are not in this round yet.'); return; }
    const bid = parseInt(myInput.value) || 0;
    postJSON('/api/bid', { playerId, bid }).catch(err => alert('Failed to submit bid: ' + err.message));
}

function submitActualsVirtual() {
    // Manual actuals no longer needed; tricks auto-tracked.
    alert('Tricks are now tracked automatically during play.');
}

function nextRoundVirtual() {
    if (role !== 'host') {
        alert('Only the host can advance rounds.');
        return;
    }
    postJSON('/api/next-round', { playerId }).catch(err => alert('Failed to advance: ' + err.message));
}

function playCard(card) {
    postJSON('/api/play-card', { playerId, card }).catch(err => alert('Play failed: ' + err.message));
}

// Shared helpers
function checkHookWarning(expectedCards) {
    const inputs = Array.from(document.querySelectorAll('.bid-input'));
    const totalBids = inputs.reduce((sum, input) => sum + (parseInt(input.value) || 0), 0);
    const warningEl = document.getElementById('hook-warning');
    if (totalBids === expectedCards) {
        warningEl.style.display = 'block';
        warningEl.innerText = `Hook Warning: Total bids (${totalBids}) equal the total cards (${expectedCards})! The dealer usually cannot make this bid.`;
    } else {
        warningEl.style.display = 'none';
    }
}

async function postJSON(url, body) {
    const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
    });
    if (!res.ok) {
        let msg = res.statusText;
        try { msg = await res.text(); } catch (_e) {}
        throw new Error(msg || 'Request failed');
    }
    const contentType = res.headers.get('content-type') || '';
    if (contentType.includes('application/json')) return res.json();
    return {};
}

// Button handlers dispatching on mode
function submitBids() {
    if (mode === 'physical') submitBidsPhysical();
    else submitBidsVirtual();
}

function submitActuals() {
    if (mode === 'physical') calculateScoresPhysical();
    else submitActualsVirtual();
}

function nextRound() {
    if (mode === 'physical') nextRoundPhysical();
    else nextRoundVirtual();
}

// Initial toggle setup
handleModeChange();
handlePresetChange();
