# Flutter 多主题切换实现笔记

本文基于当前项目已经实现的多主题切换功能，说明它的实现步骤、关键代码和每段代码的作用。

当前功能支持：

- 跟随系统主题
- 强制浅色主题
- 强制深色主题
- 多套主题色切换

---

## 1. 涉及文件

当前多主题切换主要涉及 4 个文件：

```text
lib/
  theme/
    app_theme.dart
  l10n/
    app_localizations.dart
  main.dart
test/
  widget_test.dart
```

文件职责如下：

- `lib/theme/app_theme.dart`：集中定义主题数据和主题生成方法
- `lib/main.dart`：保存当前主题状态，接入 `MaterialApp`，展示主题设置页面
- `lib/l10n/app_localizations.dart`：补充主题相关的中英文文案
- `test/widget_test.dart`：验证主题页面可以打开，并且可以切换主题模式和主题色

---

## 2. 整体实现思路

多主题切换的核心流程是：

```text
用户选择主题模式或主题色
        ↓
调用 _setThemeMode / _setSeedColor
        ↓
setState 更新 MyApp 状态
        ↓
MaterialApp 重新构建
        ↓
theme / darkTheme / themeMode 生效
        ↓
整个 App 主题刷新
```

Flutter 的主题切换不是手动去改每个页面颜色，而是更新 `MaterialApp` 的主题配置。

页面里的组件只要使用 `Theme.of(context)`、`colorScheme`、`FilledButton`、`AppBar` 等 Material 组件，就会自动跟随主题变化。

---

## 3. `AppThemeOption` 的作用

文件位置：

```text
lib/theme/app_theme.dart
```

代码：

```dart
class AppThemeOption {
  const AppThemeOption({
    required this.nameKey,
    required this.color,
  });

  final String nameKey;
  final Color color;
}
```

这个类表示一个可选主题色。

它包含两个字段：

- `nameKey`：国际化文案 key，例如 `themeColorBlue`
- `color`：真正用于生成主题的颜色

为什么不直接写中文名称？

因为当前项目已经接入了国际化，所以颜色名称也应该走：

```dart
context.l10n.text(option.nameKey)
```

这样中文环境显示“蓝色”，英文环境显示“Blue”。

---

## 4. `AppTheme` 的作用

代码：

```dart
class AppTheme {
  static const defaultSeedColor = Color(0xFF2563EB);

  static const options = [
    AppThemeOption(nameKey: 'themeColorBlue', color: Color(0xFF2563EB)),
    AppThemeOption(nameKey: 'themeColorTeal', color: Color(0xFF0F766E)),
    AppThemeOption(nameKey: 'themeColorRose', color: Color(0xFFBE123C)),
    AppThemeOption(nameKey: 'themeColorPurple', color: Color(0xFF7C3AED)),
    AppThemeOption(nameKey: 'themeColorOrange', color: Color(0xFFC2410C)),
  ];
}
```

`AppTheme` 是主题配置中心。

它目前管理两类信息：

1. 默认主题色
2. 可选主题色列表

`defaultSeedColor` 是 App 第一次启动时使用的默认颜色。

`options` 是主题设置页面展示的颜色列表。

---

## 5. `ThemeData` 如何生成

浅色主题：

```dart
static ThemeData light(Color seedColor) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );
}
```

深色主题：

```dart
static ThemeData dark(Color seedColor) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
```

这里使用的是 Material 3 推荐的 `ColorScheme.fromSeed`。

它的作用是：

- 只给一个核心颜色 `seedColor`
- Flutter 自动生成一整套配色
- 包括 primary、secondary、surface、background 等颜色

也就是说，主题色不是只改变按钮颜色，而是会生成完整色板。

---

## 6. `MyApp` 中保存主题状态

文件位置：

```text
lib/main.dart
```

代码：

```dart
ThemeMode _themeMode = ThemeMode.system;
Color _seedColor = AppTheme.defaultSeedColor;
```

这里保存了两个状态。

### 6.1 `_themeMode`

控制当前使用哪种明暗模式：

```dart
ThemeMode.system
ThemeMode.light
ThemeMode.dark
```

含义：

- `ThemeMode.system`：跟随系统
- `ThemeMode.light`：强制浅色
- `ThemeMode.dark`：强制深色

### 6.2 `_seedColor`

控制当前主题色。

例如：

```dart
Color(0xFF2563EB)
```

代表蓝色主题。

---

## 7. 修改主题模式

代码：

```dart
void _setThemeMode(ThemeMode themeMode) {
  setState(() {
    _themeMode = themeMode;
  });
}
```

这个方法在用户点击“跟随系统 / 浅色 / 深色”时调用。

调用后：

1. 更新 `_themeMode`
2. 触发 `setState`
3. `MyApp` 重新构建
4. `MaterialApp.themeMode` 使用新值

---

## 8. 修改主题色

代码：

```dart
void _setSeedColor(Color seedColor) {
  setState(() {
    _seedColor = seedColor;
  });
}
```

这个方法在用户点击颜色选项时调用。

调用后：

1. 更新 `_seedColor`
2. 触发 `setState`
3. `MaterialApp.theme` 和 `MaterialApp.darkTheme` 重新生成
4. 整个 App 使用新的主题色

---

## 9. MaterialApp 接入主题

代码：

```dart
MaterialApp(
  theme: AppTheme.light(_seedColor),
  darkTheme: AppTheme.dark(_seedColor),
  themeMode: _themeMode,
)
```

这 3 个字段是主题切换的关键。

### 9.1 `theme`

浅色主题。

当 `themeMode` 是 `ThemeMode.light` 时使用它。

系统处于浅色模式，并且 `themeMode` 是 `ThemeMode.system` 时，也使用它。

### 9.2 `darkTheme`

深色主题。

当 `themeMode` 是 `ThemeMode.dark` 时使用它。

系统处于深色模式，并且 `themeMode` 是 `ThemeMode.system` 时，也使用它。

### 9.3 `themeMode`

决定当前到底用浅色、深色，还是跟随系统。

---

## 10. 首页入口

首页目录新增了一个功能入口：

```dart
FeatureEntry(
  titleKey: 'themeTitle',
  descriptionKey: 'themeDescription',
  routeName: AppRoutes.theme,
  icon: Icons.palette,
  color: Color(0xFFC2410C),
)
```

这里仍然使用国际化 key：

- `themeTitle`
- `themeDescription`

这样首页按钮可以自动适配中文和英文。

---

## 11. 主题路由

路由常量：

```dart
static const theme = '/theme';
```

`MaterialApp.routes` 中注册：

```dart
AppRoutes.theme: (context) => ThemeSettingsPage(
      themeMode: _themeMode,
      seedColor: _seedColor,
      onThemeModeChanged: _setThemeMode,
      onSeedColorChanged: _setSeedColor,
    ),
```

这里把当前主题状态和修改方法传给主题设置页面。

这样页面本身不直接保存全局主题状态，而是通过回调通知 `MyApp` 修改。

---

## 12. `ThemeSettingsPage` 的作用

`ThemeSettingsPage` 是主题设置页面。

它接收 4 个参数：

```dart
final ThemeMode themeMode;
final Color seedColor;
final ValueChanged<ThemeMode> onThemeModeChanged;
final ValueChanged<Color> onSeedColorChanged;
```

含义：

- `themeMode`：当前主题模式
- `seedColor`：当前主题色
- `onThemeModeChanged`：切换主题模式时调用
- `onSeedColorChanged`：切换主题色时调用

这种设计的好处是：

- 页面只负责展示和触发事件
- 主题状态仍然由 `MyApp` 统一管理
- 数据流方向清楚

---

## 13. 使用 SegmentedButton 切换模式

代码：

```dart
SegmentedButton<ThemeMode>(
  showSelectedIcon: false,
  segments: [
    ButtonSegment<ThemeMode>(
      value: ThemeMode.system,
      label: Text(context.l10n.text('themeSystem')),
      icon: const Icon(Icons.settings_suggest),
    ),
    ButtonSegment<ThemeMode>(
      value: ThemeMode.light,
      label: Text(context.l10n.text('themeLight')),
      icon: const Icon(Icons.light_mode),
    ),
    ButtonSegment<ThemeMode>(
      value: ThemeMode.dark,
      label: Text(context.l10n.text('themeDark')),
      icon: const Icon(Icons.dark_mode),
    ),
  ],
  selected: {themeMode},
  onSelectionChanged: (selection) {
    onThemeModeChanged(selection.first);
  },
)
```

这里选择 `SegmentedButton` 是因为主题模式是互斥选项。

用户只能选择其中一个：

- 跟随系统
- 浅色
- 深色

---

## 14. 使用 ChoiceChip 切换主题色

代码：

```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: AppTheme.options.map((option) {
    final isSelected = option.color == seedColor;
    return ChoiceChip(
      selected: isSelected,
      label: Text(context.l10n.text(option.nameKey)),
      avatar: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: option.color,
          shape: BoxShape.circle,
        ),
      ),
      onSelected: (_) => onSeedColorChanged(option.color),
    );
  }).toList(),
)
```

这里使用 `Wrap`，是为了适配小屏幕。

如果一行放不下，颜色选项会自动换行，不容易出现溢出。

`ChoiceChip` 的作用是展示一个可选项。

`avatar` 里的圆点用来展示颜色本身。

---

## 15. 主题预览区域

主题页面底部增加了预览：

```dart
ResultPanel(
  title: context.l10n.text('themePreviewTitle'),
  content: context.l10n.text('themePreviewContent'),
  extra: Container(
    color: theme.colorScheme.primaryContainer,
    child: ...
  ),
)
```

预览区域使用：

```dart
theme.colorScheme.primaryContainer
theme.colorScheme.onPrimaryContainer
```

这说明它不是写死颜色，而是读取当前主题中的颜色。

所以当用户切换主题色或明暗模式时，预览区域也会跟着变化。

---

## 16. 国际化文案

主题相关文案放在：

```text
lib/l10n/app_localizations.dart
```

中文文案包括：

```dart
'themeTitle': '多主题切换',
'themeDescription': '演示 ThemeMode、浅色/深色模式和主题色切换。',
'themeSystem': '跟随系统',
'themeLight': '浅色',
'themeDark': '深色',
```

英文文案包括：

```dart
'themeTitle': 'Theme switching',
'themeDescription': 'Learn ThemeMode, light/dark mode, and seed color switching.',
'themeSystem': 'System',
'themeLight': 'Light',
'themeDark': 'Dark',
```

这样主题页面也能跟随 App 语言切换。

---

## 17. 测试覆盖

测试文件：

```text
test/widget_test.dart
```

新增测试：

```dart
testWidgets('opens theme page and switches theme options', (
  WidgetTester tester,
) async {
  await pumpChineseApp(tester);

  await tester.tap(find.text('多主题切换'));
  await tester.pumpAndSettle();

  expect(find.text('主题模式'), findsOneWidget);
  expect(find.text('主题色'), findsOneWidget);

  await tester.tap(find.text('深色'));
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(ChoiceChip, '玫红'));
  await tester.pumpAndSettle();

  expect(find.text('主题预览'), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

这个测试验证了：

- 首页可以进入主题页
- 主题页显示主题模式区域
- 主题页显示主题色区域
- 可以切换深色模式
- 可以切换玫红主题色
- 页面没有渲染异常

---

## 18. 当前方案还没有做什么

当前实现是运行时状态切换。

也就是说：

- App 运行时可以切换主题
- App 重启后会恢复默认主题

如果要让用户选择永久保存，需要继续接入本地存储，例如：

- `shared_preferences`
- 本地数据库
- 自己写文件缓存

推荐下一步使用 `shared_preferences` 保存：

```text
themeMode: system / light / dark
seedColor: 0xFF2563EB
```

启动时读取这些值，再初始化 `MyApp`。

---

## 19. 一句话总结

多主题切换的本质不是逐个修改页面颜色，而是把主题状态保存在 `MyApp` 中，再通过 `MaterialApp.theme`、`MaterialApp.darkTheme` 和 `MaterialApp.themeMode` 统一驱动整个 App 的视觉样式。

