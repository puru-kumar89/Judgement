import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stepper_input.dart';
import '../../theme/theme_provider.dart';
import '../widgets/player_avatar.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> with SingleTickerProviderStateMixin {
  bool _showAdvanced = false;
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void dispose() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _getNode(String id) {
    return _focusNodes.putIfAbsent(id, () => FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final theme = ref.watch(themeProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad(context), vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GAME INITIALIZATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: theme.accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'SETUP',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  color: theme.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Players block
          PremiumRowCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PLAYERS', style: TextStyle(fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: theme.textMain)),
                      ],
                    ),
                    if (state.players.length < 10)
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: notifier.addPlayer,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('ADD'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: theme.surfaceCard,
                            foregroundColor: theme.accent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(color: theme.borderCard),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ReorderableListView.builder(
                  key: const PageStorageKey('players_reorder'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.players.length,
                  onReorder: notifier.reorderPlayers,
                  itemBuilder: (context, index) {
                    final p = state.players[index];
                    final isDealer = index == 0;
                    return Padding(
                      key: ValueKey(p.id),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PremiumRowCard(
                        isActive: isDealer,
                        padding: EdgeInsets.zero, // Remove padding from card to allow GestureDetector full reach
                        child: GestureDetector(
                          onTap: () => _getNode(p.id).requestFocus(),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(Icons.drag_indicator, color: theme.textMuted),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        focusNode: _getNode(p.id),
                                        initialValue: p.name,
                                        onChanged: (val) => notifier.updatePlayerName(p.id, val),
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textMain),
                                        decoration: InputDecoration(
                                          hintText: 'Player ${index + 1}',
                                          hintStyle: TextStyle(color: theme.textMuted),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [AutofillHints.name],
                                      ),
                                      const SizedBox(height: 2),
                                      if (isDealer)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.accent.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text('DEALER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: theme.accent)),
                                        )
                                      else
                                        GestureDetector(
                                          onTap: () => notifier.setDealer(p.id),
                                          child: Text('Set as Dealer', style: TextStyle(fontSize: 12, color: theme.textMuted, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                                        ),
                                    ],
                                  ),
                                ),
                                if (state.players.length > 3)
                                  IconButton(
                                    icon: Icon(Icons.close, color: theme.textMuted, size: 18),
                                    onPressed: () => notifier.removePlayer(p.id),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Text('RULES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: theme.textMuted)),
          const SizedBox(height: 10),

          PremiumRowCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('STARTING CARDS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text('Max for ${state.players.length} players is ${notifier.maxPossibleCards}', style: TextStyle(fontSize: 11, color: theme.accent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    StepperInput(
                      value: state.startingCards,
                      min: 1,
                      max: notifier.maxPossibleCards,
                      onChanged: (val) => notifier.updateSettings(startingCards: val),
                      compact: true,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          PremiumRowCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ROUND STYLE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(
                        state.roundStyle == 'countdown'
                            ? 'Cards count down from ${state.startingCards} to 1 each round'
                            : 'Every round is played with ${state.startingCards} cards',
                        style: TextStyle(fontSize: 11, color: theme.textMuted),
                      ),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  value: state.roundStyle,
                  underline: const SizedBox(),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textMain),
                  icon: Icon(Icons.keyboard_arrow_down, color: theme.textMuted),
                  dropdownColor: theme.surfaceCard,
                  items: const [
                    DropdownMenuItem(value: 'countdown', child: Text('Countdown')),
                    DropdownMenuItem(value: 'constant', child: Text('Constant')),
                  ],
                  onChanged: (val) => notifier.updateSettings(roundStyle: val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          InkWell(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Row(
              children: [
                Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, color: theme.textMuted),
                const SizedBox(width: 6),
                Text('Advanced Settings', style: TextStyle(color: theme.textMuted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (_showAdvanced)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: PremiumRowCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include No-Trump (NT)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Adds a round where no suit is trump', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                      value: state.includeNoTrump,
                      activeColor: theme.accent,
                      onChanged: (val) => notifier.updateSettings(includeNoTrump: val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Lenient Overtricks', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Winning extra tricks gives a small bonus instead of penalty', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                      value: state.lenientOvertrick,
                      activeColor: theme.accent,
                      onChanged: (val) => notifier.updateSettings(lenientOvertrick: val),
                    ),
                    const Divider(),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Points per Exact Bid', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Pts earned per trick when bid is exact (default: 10)', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        StepperInput(
                          value: state.successMultiplier,
                          min: 1,
                          max: 50,
                          onChanged: (val) => notifier.updateSettings(successMultiplier: val),
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Penalty Per Missed Bid', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Pts deducted per trick you over/under-bid (default: 10)', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        StepperInput(
                          value: state.penaltyMultiplier,
                          min: 1,
                          max: 50,
                          onChanged: (val) => notifier.updateSettings(penaltyMultiplier: val),
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.save_outlined, color: theme.textMain),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textMain,
                    side: BorderSide(color: theme.borderCard),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await notifier.saveCurrentSettings();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preferences saved')),
                      );
                    }
                  },
                  label: const Text('Save Preferences'),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset to Defaults?'),
                      content: const Text('This will reset all game rules to defaults. Player names will not be affected.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirmed == true) await notifier.resetSettings();
                },
                child: Text('Reset to Defaults', style: TextStyle(color: theme.textMuted, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: notifier.hasActiveGame ? 'Start / Continue' : 'Start Game',
            onPressed: () async {
              // Validate names first
              final activePlayers = state.players.where((p) => p.name.trim().isNotEmpty).toList();
              if (activePlayers.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter names for at least 3 players.')),
                );
                return;
              }
              final unnamed = state.players.where((p) => p.name.trim().isEmpty).toList();
              if (unnamed.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a name for every player, or remove empty slots.')),
                );
                return;
              }

              // If a game is already in progress, present 3 options
              if (notifier.hasActiveGame) {
                final choice = await showDialog<String>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Active game in progress'),
                    content: const Text(
                        'You have an ongoing game with saved scores.\n\nWhat would you like to do?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, 'continue'),
                        child: const Text('Continue Game'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, 'rules'),
                        child: const Text('Apply New Rules'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, 'new'),
                        child: const Text('New Game', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (choice == null || !context.mounted) return;

                if (choice == 'continue') {
                  // Confirm and resume
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Resume game?'),
                      content: const Text('You\'ll be taken back to where you left off. Any setup changes made will not be applied.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Resume')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) notifier.continueGame();

                } else if (choice == 'rules') {
                  // Confirm and apply new rules keeping scores
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Apply new rules?'),
                      content: const Text('Current scores are kept. The updated settings will take effect from the next round onwards.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply Rules')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    notifier.applyNewRules();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rules updated! Scoring changes apply now; card count & trump changes apply from next round.'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }

                } else if (choice == 'new') {
                  // Confirm and start fresh
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Start a new game?'),
                      content: const Text('This will permanently end the current game and reset all scores. This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Start New Game', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    final really = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm reset'),
                        content: const Text('All rounds and scores will be wiped. This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Go Back')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Yes, reset', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (really == true && context.mounted) notifier.newGame();
                  }
                }
                return;
              }

              // No active game — start normally
              try {
                notifier.startGame();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
