import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: KaatApp()));
}

class KaatApp extends StatelessWidget {
  const KaatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaat Score Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
