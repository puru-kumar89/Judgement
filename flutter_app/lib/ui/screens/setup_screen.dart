import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stepper_input.dart';
import '../../theme/app_theme.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Game Setup',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Players', style: Theme.of(context).textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: () => notifier.addPlayer(),
                      icon: const Icon(Icons.add, color: AppTheme.accent, size: 18),
                      label: const Text('Add', style: TextStyle(color: AppTheme.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...state.players.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: p.name,
                          onChanged: (val) => notifier.updatePlayerName(p.id, val),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.cardBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      if (state.players.length > 3)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger),
                          onPressed: () => notifier.removePlayer(p.id),
                        ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Starting Cards:', style: TextStyle(fontWeight: FontWeight.bold)),
                    StepperInput(
                      value: state.startingCards,
                      min: 1,
                      max: 20,
                      onChanged: (val) => notifier.updateSettings(startingCards: val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Round Style:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: state.roundStyle,
                      dropdownColor: AppTheme.bgInk,
                      items: const [
                        DropdownMenuItem(value: 'countdown', child: Text('Countdown')),
                        DropdownMenuItem(value: 'constant', child: Text('Constant')),
                      ],
                      onChanged: (val) => notifier.updateSettings(roundStyle: val),
                    ),
                  ],
                ),
                Divider(color: AppTheme.cardBorder, height: 32),
                InkWell(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Row(
                    children: [
                      Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Text('Advanced Settings', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (_showAdvanced) Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lenient Overtricks'),
                        value: state.lenientOvertrick,
                        activeColor: AppTheme.accent,
                        onChanged: (val) => notifier.updateSettings(lenientOvertrick: val),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Success Multiplier:'),
                          StepperInput(
                            value: state.successMultiplier,
                            min: 1, max: 50,
                            onChanged: (val) => notifier.updateSettings(successMultiplier: val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Penalty Multiplier:'),
                          StepperInput(
                            value: state.penaltyMultiplier,
                            min: 1, max: 50,
                            onChanged: (val) => notifier.updateSettings(penaltyMultiplier: val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              try {
                notifier.startGame();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Start Game'),
          ),
        ],
      ),
    );
  }
}
