import 'package:material_ui/material_ui.dart';

class AppThemeController {
  AppThemeController._();

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier(ThemeMode.system);

  static void setDark(bool dark) {
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;
  }
}
