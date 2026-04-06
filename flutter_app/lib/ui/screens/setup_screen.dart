import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stepper_input.dart';
import '../../theme/theme_provider.dart';
import '../widgets/player_avatar.dart';
import '../widgets/primary_button.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final theme = ref.watch(themeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 24),

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
                        const SizedBox(height: 2),
                        Text('Add up to 7 players to the table', style: TextStyle(fontSize: 12, color: theme.textMuted)),
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
                ...state.players.asMap().entries.map((entry) {
                  final p = entry.value;
                  final isDealer = entry.key == state.players.length - 1;
                  return Padding(
                    key: ValueKey(p.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PremiumRowCard(
                      isActive: isDealer,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          PlayerAvatar(name: p.name, solid: isDealer),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  initialValue: p.name,
                                  onChanged: (val) => notifier.updatePlayerName(p.id, val),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textMain),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (isDealer)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('CURRENT DEALER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: theme.accent)),
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
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Text('RULES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: theme.textMuted)),
          const SizedBox(height: 10),

          PremiumRowCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STARTING CARDS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('Pick how many each player starts with', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                  ],
                ),
                StepperInput(
                  value: state.startingCards,
                  min: 1,
                  max: 20,
                  onChanged: (val) => notifier.updateSettings(startingCards: val),
                  compact: true,
                ),
              ],
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
                      Text('Cards decrease by 1 each round', style: TextStyle(fontSize: 11, color: theme.textMuted)),
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
                      value: state.includeNoTrump,
                      activeColor: theme.accent,
                      onChanged: (val) => notifier.updateSettings(includeNoTrump: val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Lenient Overtricks', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: state.lenientOvertrick,
                      activeColor: theme.accent,
                      onChanged: (val) => notifier.updateSettings(lenientOvertrick: val),
                    ),
                    const Divider(),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Success Base Points', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Text('Penalty Multiplier', style: TextStyle(fontWeight: FontWeight.bold)),
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
          PrimaryButton(
            label: 'Start Game',
            onPressed: () {
              try {
                notifier.startGame();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
          ),
        ],
      ),
    );
  }
}
