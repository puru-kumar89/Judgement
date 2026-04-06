import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'theme/theme_provider.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: KaatApp()));
}

class KaatApp extends ConsumerWidget {
  const KaatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Kaat Score Tracker',
      debugShowCheckedModeBanner: false,
      theme: appTheme.themeData,
      home: const HomeScreen(),
    );
  }
}
