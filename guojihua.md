# Flutter 国际化学习笔记

这份笔记对应当前项目里已经抽离后的国际化结构。  
现在国际化逻辑已经从 `lib/main.dart` 中拆出，集中放到：

- `lib/l10n/app_localizations.dart`
- `lib/main.dart`
- `test/widget_test.dart`

目标是把职责分清：

- `l10n` 文件夹负责“国际化基础设施”
- `main.dart` 负责“页面、路由、语言切换入口”
- 测试负责“验证中文、英文和窄屏布局”

---

## 1. 目录结构

当前国际化相关代码建议这样理解：

```text
lib/
  l10n/
    app_localizations.dart
  main.dart
test/
  widget_test.dart
```

这样做的好处很直接：

1. 国际化逻辑集中，主文件更干净
2. 页面代码不再混着文案表和代理实现
3. 后续迁移到官方 `gen-l10n` 更顺

---

## 2. 方案总览

当前项目采用的是“手写本地化类 + LocalizationsDelegate + MaterialApp 接入”的轻量方案。

核心链路是：

```text
Locale
  -> AppLocalizations
  -> LocalizationsDelegate
  -> MaterialApp
  -> context.l10n.text(...)
```

你可以把它理解成 4 层：

1. 定义支持哪些语言
2. 定义每种语言的文案
3. 告诉 Flutter 怎么加载文案
4. 页面里按 key 读取文案

---

## 3. `lib/l10n/app_localizations.dart`

这个文件是国际化的核心实现。

### 3.1 作用

它负责：

- 声明支持的语言
- 保存中英文文案
- 提供读取文案的方法
- 暴露 `LocalizationsDelegate`
- 提供 `BuildContext.l10n` 扩展

### 3.2 代码结构

文件里最重要的几个部分是：

```dart
class AppLocalizations
class _AppLocalizationsDelegate
extension L10nContext on BuildContext
```

---

## 4. `supportedLocales`

```dart
static const supportedLocales = [
  Locale('zh'),
  Locale('en'),
];
```

这段代码告诉 Flutter：

- App 支持中文
- App 支持英文

如果未来要加日文、韩文、法文，就继续往这里加：

```dart
Locale('ja')
Locale('ko')
Locale('fr')
```

---

## 5. 文案数据 `_values`

国际化最核心的数据就是文案表。

当前项目使用嵌套 Map：

```dart
static const Map<String, Map<String, String>> _values = {
  'zh': {
    'homeTitle': 'MethodChannel 学习目录',
    'i18nTitle': '国际化代码示例',
  },
  'en': {
    'homeTitle': 'MethodChannel Study Directory',
    'i18nTitle': 'Internationalization example',
  },
};
```

第一层是语言代码，第二层是文案 key。

好处是：

- 写起来快
- 结构直观
- 学习成本低

缺点也很明显：

- 文案多了以后会比较长
- 没有 `.arb` 那么规范

所以这套方案更适合入门和教学。

---

## 6. `text()` 方法

```dart
String text(String key) {
  return _values[locale.languageCode]?[key] ?? _values['zh']![key] ?? key;
}
```

它的作用是读取普通静态文案。

读取顺序是：

1. 先找当前语言
2. 找不到就回退中文
3. 中文也没有就返回 key 本身

例如：

```dart
context.l10n.text('homeTitle')
```

如果当前语言是中文，结果是：

```text
MethodChannel 学习目录
```

如果当前语言是英文，结果是：

```text
MethodChannel Study Directory
```

---

## 7. `format()` 方法

有些文案需要动态参数，比如：

```text
当前电量：85%
```

这时就不能只返回固定字符串。

当前项目用的是：

```dart
String format(String key, Map<String, Object?> values) {
  var template = text(key);
  for (final entry in values.entries) {
    template = template.replaceAll('{${entry.key}}', '${entry.value}');
  }
  return template;
}
```

示例：

```dart
context.l10n.format('batterySuccess', {'value': batteryLevel})
```

如果 `batteryLevel` 是 `85`，中文就会显示：

```text
当前电量：85%
```

英文就会显示：

```text
Current battery level: 85%
```

---

## 8. `LocalizationsDelegate`

Flutter 需要一个代理来知道如何创建 `AppLocalizations`：

```dart
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) { ... }

  @override
  Future<AppLocalizations> load(Locale locale) async { ... }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
```

### 8.1 `isSupported`

判断当前语言是否在支持列表里。

### 8.2 `load`

根据 `Locale` 创建对应的 `AppLocalizations`。

### 8.3 `shouldReload`

这里返回 `false`，因为文案是写死在代码里的，不需要热重载。

---

## 9. `localizationDelegates`

现在在 `AppLocalizations` 里暴露了一个统一列表：

```dart
static const localizationDelegates = [
  delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
```

这样 `main.dart` 就不用自己拼 4 个代理了，直接引用一个列表即可。

这一步就是“抽离”的重点之一。

---

## 10. `BuildContext.l10n`

```dart
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

它的作用是简化页面写法。

有了它，页面里可以直接写：

```dart
context.l10n.text('homeTitle')
```

而不是：

```dart
AppLocalizations.of(context).text('homeTitle')
```

这只是语法糖，但会让页面可读性更好。

---

## 11. `main.dart` 现在做什么

现在 `main.dart` 不再保存整套国际化实现，只负责接入。

它主要负责：

- App 启动
- 路由
- 当前语言状态 `_locale`
- 切换语言 `_setLocale`
- 把 `AppLocalizations` 接进 `MaterialApp`

### 11.1 `MyApp` 为什么是 `StatefulWidget`

因为语言要动态切换。

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialLocale});

  final Locale? initialLocale;
}
```

如果语言是固定不变的，`StatelessWidget` 也可以。

但这里需要运行时切换，所以用 `StatefulWidget`。

---

## 12. `locale` 的控制

当前语言保存在：

```dart
Locale? _locale;
```

初始化时：

```dart
@override
void initState() {
  super.initState();
  _locale = widget.initialLocale;
}
```

切换语言时：

```dart
void _setLocale(Locale? locale) {
  setState(() {
    _locale = locale;
  });
}
```

这里的关键点是：

- `Locale('zh')` -> 强制中文
- `Locale('en')` -> 强制英文
- `null` -> 跟随系统

---

## 13. `MaterialApp` 如何接入国际化

现在的写法是：

```dart
MaterialApp(
  onGenerateTitle: (context) => context.l10n.text('appTitle'),
  locale: _locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationDelegates,
)
```

逐项看：

### `onGenerateTitle`

让窗口标题也跟语言走。

### `locale`

控制当前语言。

### `supportedLocales`

告诉 Flutter 这个 App 支持哪些语言。

### `localizationsDelegates`

把本地化代理挂进去。

---

## 14. 页面如何使用国际化文案

页面里不要直接写死中文或英文，而是读 key。

例如首页标题：

```dart
Text(context.l10n.text('homeTitle'))
```

示例页标题：

```dart
Text(context.l10n.text('batteryTitle'))
```

动态错误信息：

```dart
context.l10n.format('missingPlugin', {'method': methodName})
```

这样写的好处是：

- 页面逻辑和文案解耦
- 后续加语言只改文案表
- 页面不用到处找字符串

---

## 15. 国际化示例页的作用

`I18nExamplePage` 是专门给学习者看的页面。

它演示了 3 件事：

1. 当前语言显示什么文案
2. 如何切换中文、英文、系统语言
3. 如何写一段真正可复用的国际化代码

它接收两个参数：

```dart
currentLocale
onLocaleChanged
```

前者用于显示当前状态，后者用于切换语言。

---

## 16. 测试为什么要固定中文

在 `test/widget_test.dart` 里，测试会显式传入：

```dart
const MyApp(initialLocale: Locale('zh'))
```

原因是测试环境不一定默认中文。

如果不固定语言，断言可能会因为系统 Locale 不同而失败。

这也是国际化项目里很常见的测试写法。

---

## 17. 当前方案的优点

这套方案适合学习，主要因为：

- 代码少
- 结构清楚
- 能看懂 Flutter 国际化的工作流程
- 不需要先学习 `.arb` 和代码生成

对于教学项目，这是合适的。

---

## 18. 当前方案的不足

手写 Map 的问题也要知道：

- 文案多了会很长
- 复杂复数规则不好处理
- 翻译协作不方便
- 类型安全不如官方生成代码

所以它适合：

- 学习
- 小项目
- Demo

正式项目还是建议升级为官方 `gen-l10n`。

---

## 19. 如果后续升级到 gen-l10n

后续可以把这套手写方案迁移成：

```text
lib/l10n/app_zh.arb
lib/l10n/app_en.arb
```

然后交给 Flutter 自动生成本地化类。

那时页面会更像这样：

```dart
AppLocalizations.of(context)!.homeTitle
```

这比手写 Map 更标准，也更适合团队协作。

---

## 20. 学习顺序建议

如果你要按顺序理解这套方案，建议先看：

1. `lib/l10n/app_localizations.dart`
2. `main.dart` 中的 `MaterialApp` 配置
3. `I18nExamplePage`
4. `test/widget_test.dart`

理解顺序最好是：

```text
文案表 -> 代理 -> MaterialApp -> 页面读取 -> 测试验证
```

---

## 21. 本项目已经验证过的点

当前国际化方案已经通过：

- `dart analyze`
- `flutter test`

验证项包括：

- 首页中文目录显示
- 窄屏中文不溢出
- 页面跳转
- 中英文切换
- 媒体页面入口

---

## 22. 一句话总结

当前项目的国际化已经从“混在 `main.dart` 里”优化成了“`l10n` 文件夹专门管理国际化基础设施，`main.dart` 只负责接入和页面逻辑”。  
这样结构更清楚，也更接近正式项目的组织方式。

