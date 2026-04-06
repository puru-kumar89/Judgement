import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app_theme.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeData>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeData> {
  bool _isDark = false;

  ThemeNotifier() : super(AppThemeData.light());

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    state = _isDark ? AppThemeData.dark() : AppThemeData.light();
  }
}
