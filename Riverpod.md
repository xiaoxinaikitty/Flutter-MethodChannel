# Flutter 状态管理学习笔记：重点 Riverpod

本文按照当前项目的学习路线整理：

```text
setState
  -> ValueNotifier
  -> ChangeNotifier / Provider 思想
  -> Riverpod
  -> Bloc / Cubit
```

你已经有 GetX 基础，所以重点不是再学一个“能改 UI 的工具”，而是学习更清晰的状态边界、依赖管理、异步状态和可测试性。

当前项目已经新增状态管理学习页面：

```text
lib/state_management/
  state_management_page.dart
  builtin_state_examples.dart
  riverpod_examples.dart
  bloc_cubit_notes.dart
  state_learning_widgets.dart
```

首页入口：

```text
状态管理学习
```

---

## 1. 为什么先理解 Flutter 原生状态

状态管理不是一上来就选库。

先判断状态属于哪一类：

```text
页面内部小状态 -> setState
单个值监听 -> ValueNotifier
对象级状态 -> ChangeNotifier
跨页面、依赖、异步状态 -> Riverpod / Bloc
```

如果一个状态只影响当前页面，直接用 `setState` 更简单。

如果一个状态需要跨页面共享、可测试、异步加载、缓存，就应该使用更完整的状态管理方案。

---

## 2. setState

`setState` 是 Flutter 最基础的状态管理。

示例：

```dart
int count = 0;

FilledButton(
  onPressed: () {
    setState(() {
      count++;
    });
  },
  child: const Text('增加'),
)
```

特点：

- 简单
- 原生
- 适合页面内部状态

缺点：

- 不适合跨页面共享
- 页面复杂后容易把 UI 和业务逻辑混在一起

---

## 3. ValueNotifier

`ValueNotifier` 适合管理单个值。

示例：

```dart
final ValueNotifier<int> count = ValueNotifier<int>(0);

ValueListenableBuilder<int>(
  valueListenable: count,
  builder: (context, value, child) {
    return Text('count: $value');
  },
);
```

修改状态：

```dart
count.value++;
```

特点：

- 比 `setState` 更细粒度
- 只重建监听区域
- 适合简单响应式值

---

## 4. ChangeNotifier

`ChangeNotifier` 适合一个对象里有多个状态字段。

示例：

```dart
class CounterChangeNotifier extends ChangeNotifier {
  int count = 0;

  void increment() {
    count++;
    notifyListeners();
  }
}
```

重点：

- 修改字段后必须调用 `notifyListeners`
- UI 通过监听器刷新
- Provider 的很多基础用法就是围绕 `ChangeNotifier` 展开的

---

## 5. 为什么重点学习 Riverpod

你已经会 GetX，下一步推荐 Riverpod，原因是：

1. 不依赖 `BuildContext`
2. 依赖关系更清晰
3. 测试更方便
4. 异步状态表达更自然
5. 适合把全局状态、服务、缓存、接口请求统一管理

GetX 更像“快速开发工具箱”。

Riverpod 更像“状态和依赖建模工具”。

---

## 6. 项目如何接入 Riverpod

当前项目在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
```

App 入口包裹 `ProviderScope`：

```dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```

`ProviderScope` 是 Riverpod 的全局容器。

没有它，页面中不能使用：

```dart
ref.watch(...)
ref.read(...)
```

---

## 7. Provider：只读依赖

当前项目示例：

```dart
final appNameProvider = Provider<String>((ref) {
  return 'MethodChannel 状态管理学习';
});
```

页面读取：

```dart
final appName = ref.watch(appNameProvider);
```

适合放：

- App 配置
- Repository
- Service
- 不需要 UI 直接修改的依赖

---

## 8. StateProvider：简单可变状态

当前项目示例：

```dart
final riverpodCounterProvider = StateProvider<int>((ref) {
  return 0;
});
```

读取：

```dart
final counter = ref.watch(riverpodCounterProvider);
```

修改：

```dart
ref.read(riverpodCounterProvider.notifier).state++;
```

适合：

- 计数器
- 开关
- 筛选条件
- 当前 tab index

不适合复杂业务逻辑。

如果状态修改逻辑开始变多，应该升级为 `NotifierProvider`。

---

## 9. NotifierProvider：封装业务逻辑

当前项目示例：

```dart
final todoListProvider =
    NotifierProvider<TodoListNotifier, List<String>>(TodoListNotifier.new);
```

Notifier：

```dart
class TodoListNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ['阅读 Riverpod 基础概念'];
  }

  void add(String text) {
    final value = text.trim();
    if (value.isEmpty) {
      return;
    }
    state = [...state, value];
  }

  void remove(String value) {
    state = [
      for (final item in state)
        if (item != value) item,
    ];
  }
}
```

页面调用：

```dart
ref.read(todoListProvider.notifier).add(_todoController.text);
```

重点：

- `build()` 返回初始状态
- `state = ...` 修改状态
- 不要直接修改原 List
- 用新 List 替换旧 List，UI 才能稳定刷新

---

## 10. FutureProvider：异步状态

当前项目示例：

```dart
final asyncMessageProvider = FutureProvider<String>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 350));
  return 'FutureProvider 已完成一次模拟异步请求';
});
```

页面读取：

```dart
final asyncMessage = ref.watch(asyncMessageProvider);
```

处理状态：

```dart
asyncMessage.when(
  loading: () => const LinearProgressIndicator(),
  error: (error, stackTrace) => Text('请求失败：$error'),
  data: (message) => Text(message),
)
```

刷新：

```dart
ref.invalidate(asyncMessageProvider);
```

适合：

- 网络请求
- 本地缓存读取
- MethodChannel 异步调用
- 初始化配置

---

## 11. ref.watch、ref.read、ref.listen

### ref.watch

监听 provider。

状态变化时，当前 Widget 会重新 build。

```dart
final count = ref.watch(counterProvider);
```

### ref.read

只读取一次。

常用于按钮点击事件。

```dart
ref.read(counterProvider.notifier).state++;
```

### ref.listen

监听状态变化并执行副作用。

常用于：

- 弹 SnackBar
- 跳转页面
- 打日志

示例：

```dart
ref.listen(counterProvider, (previous, next) {
  if (next == 10) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('计数到 10 了')),
    );
  }
});
```

---

## 12. Riverpod 和 GetX 的区别

### GetX

优点：

- 上手快
- 代码少
- 路由、依赖、状态一套都能做

缺点：

- 容易全局耦合
- 状态来源可能不够清晰
- 大项目测试和维护容易变难

### Riverpod

优点：

- 状态来源清楚
- 不依赖 `BuildContext`
- 依赖关系可追踪
- 异步状态表达更规范
- 测试更方便

缺点：

- 概念比 GetX 多
- 初学需要理解 provider 的生命周期

---

## 13. Riverpod 和 Bloc / Cubit 的区别

### Riverpod

更像依赖和状态管理容器。

适合：

- 全局配置
- 异步请求
- 缓存
- 轻中型业务状态
- Repository / Service 注入

### Bloc / Cubit

更像业务流建模工具。

适合：

- 复杂业务流程
- 多人协作
- 明确事件输入和状态输出
- 企业级强规范项目

学习建议：

```text
先学 Riverpod
再学 Cubit
最后学完整 Bloc
```

---

## 14. 当前项目下一步练习建议

当前项目里最适合改造成 Riverpod 的状态有：

```text
Locale? _locale
ThemeMode _themeMode
Color _seedColor
```

可以拆成：

```text
lib/state_management/app_state/
  locale_provider.dart
  theme_provider.dart
```

例如主题状态可以建模成：

```dart
class AppThemeState {
  const AppThemeState({
    required this.themeMode,
    required this.seedColor,
  });

  final ThemeMode themeMode;
  final Color seedColor;
}
```

然后用：

```dart
NotifierProvider<AppThemeNotifier, AppThemeState>
```

管理主题切换。

这样 `MyApp` 就可以通过 `ref.watch` 读取全局主题，而不再自己保存 `_themeMode` 和 `_seedColor`。

---

## 15. 面试回答模板

可以这样回答状态管理选择：

```text
如果只是页面内部的简单 UI 状态，我会使用 setState。
如果只是单个响应式值，可以使用 ValueNotifier。
如果是简单共享状态，可以使用 ChangeNotifier 或 Provider。
如果项目中有较多异步请求、依赖注入、全局状态和缓存，我更倾向 Riverpod。
如果团队强调严格业务流、事件驱动和可测试性，也可以使用 Bloc / Cubit。
```

Riverpod 面试总结：

```text
Riverpod 是一个不依赖 BuildContext 的响应式状态管理和依赖注入方案。
它通过 Provider 暴露状态或依赖，通过 ref.watch 监听变化，通过 ref.read 触发操作。
复杂业务状态可以封装到 NotifierProvider 中，异步状态可以使用 FutureProvider 或 AsyncNotifierProvider。
相比 GetX，Riverpod 的依赖关系更显式，测试和长期维护更友好。
```

