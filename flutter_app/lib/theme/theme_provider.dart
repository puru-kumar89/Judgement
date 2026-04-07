import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app_theme.dart';

enum ThemeVariant { light, dark, premium }

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeData>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeData> {
  ThemeVariant _variant = ThemeVariant.dark;

  ThemeNotifier() : super(AppThemeData.dark());

  ThemeVariant get variant => _variant;

  void toggleTheme() {
    switch (_variant) {
      case ThemeVariant.light:
        _variant = ThemeVariant.dark;
        state = AppThemeData.dark();
        break;
      case ThemeVariant.dark:
        _variant = ThemeVariant.premium;
        state = AppThemeData.premium();
        break;
      case ThemeVariant.premium:
        _variant = ThemeVariant.light;
        state = AppThemeData.light();
        break;
    }
  }

  void setTheme(ThemeVariant variant) {
    _variant = variant;
    switch (variant) {
      case ThemeVariant.light:
        state = AppThemeData.light();
        break;
      case ThemeVariant.dark:
        state = AppThemeData.dark();
        break;
      case ThemeVariant.premium:
        state = AppThemeData.premium();
        break;
    }
  }
}
