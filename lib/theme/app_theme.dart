import 'package:flutter/material.dart';

/// 一个可选择的主题色配置。
///
/// nameKey 不直接写中文或英文，而是保存国际化 key，
/// 页面展示时通过 context.l10n.text(nameKey) 读取当前语言的名称。
class AppThemeOption {
  const AppThemeOption({
    required this.nameKey,
    required this.color,
  });

  final String nameKey;
  final Color color;
}

/// 应用主题配置中心。
///
/// 这里不放页面代码，只负责定义：
/// - 默认主题色
/// - 可选主题色列表
/// - 浅色 ThemeData
/// - 深色 ThemeData
class AppTheme {
  /// App 首次启动时使用的默认主题色。
  static const defaultSeedColor = Color(0xFF2563EB);

  /// 主题设置页展示的所有颜色选项。
  ///
  /// 增加新主题色时，只需要往这个列表里追加 AppThemeOption，
  /// 并在 app_localizations.dart 中补上对应 nameKey 的中英文文案。
  static const options = [
    AppThemeOption(nameKey: 'themeColorBlue', color: Color(0xFF2563EB)),
    AppThemeOption(nameKey: 'themeColorTeal', color: Color(0xFF0F766E)),
    AppThemeOption(nameKey: 'themeColorRose', color: Color(0xFFBE123C)),
    AppThemeOption(nameKey: 'themeColorPurple', color: Color(0xFF7C3AED)),
    AppThemeOption(nameKey: 'themeColorOrange', color: Color(0xFFC2410C)),
  ];

  /// 根据 seedColor 生成浅色主题。
  ///
  /// ColorScheme.fromSeed 会按照 Material 3 规则从一个种子色
  /// 推导出 primary、secondary、surface 等完整色板。
  static ThemeData light(Color seedColor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  /// 根据 seedColor 生成深色主题。
  ///
  /// 和 light 的区别只在 brightness，
  /// 这样浅色/深色主题能共享同一套主题色来源。
  static ThemeData dark(Color seedColor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
