# Flutter 面试题整理

## 目录

1. [Flutter 的渲染机制](#1-flutter-的渲染机制)
2. [如何与原生通信](#2-如何与原生通信)
3. [如何实现国际化](#3-如何实现国际化)
4. [Flutter 中的消息队列](#4-flutter-中的消息队列)
5. [异步的实现方式](#5-异步的实现方式)
6. [setState 后的生命周期](#6-setstate-后的生命周期)
7. [怎么自定义一个组件](#7-怎么自定义一个组件)
8. [pubspec.yaml 干什么的](#8-pubspecyaml-干什么的)
9. [怎么自定义画板，继承的什么](#9-怎么自定义画板继承的什么)
10. [如何避免重绘](#10-如何避免重绘)
11. [找到一个未排序数组中的第 k 个元素](#11-找到一个未排序数组中的第-k-个元素)
12. [网络请求你是用什么实现的](#12-网络请求你是用什么实现的)
13. [Dio 比 Http 多的功能有哪些](#13-dio-比-http-多的功能有哪些)
14. [关于非对称加密和对称加密你知道多少](#14-关于非对称加密和对称加密你知道多少)
15. [HTTP 和 HTTPS 有什么不同，加密的方式有哪种](#15-http-和-https-有什么不同加密的方式有哪种)
16. [如何实现多主题切换](#16-如何实现多主题切换)
17. [几种状态管理的优缺点](#17-几种状态管理的优缺点)
18. [MVC、MVVM、MVP 架构有什么区别](#18-mvcmvvmmvp-架构有什么区别)

## 1. Flutter 的渲染机制

Flutter 的渲染机制可以从三棵树理解：`Widget Tree`、`Element Tree`、`RenderObject Tree`。

- `Widget`：不可变的 UI 配置，描述界面应该长什么样。
- `Element`：Widget 的实例化对象，负责维护 Widget 和 RenderObject 的关系，也负责复用。
- `RenderObject`：真正参与布局、绘制和命中测试的对象。

Flutter 一帧渲染的大致流程：

1. 开发者调用 `setState`、状态管理通知更新，或者动画触发刷新。
2. Flutter 将对应的 `Element` 标记为 dirty。
3. 下一帧开始时，执行 build，重新生成 Widget 配置。
4. Element 对比新旧 Widget，尽量复用已有 Element 和 RenderObject。
5. RenderObject 执行布局，计算大小和位置。
6. RenderObject 执行绘制，生成 Layer。
7. Flutter Engine 将 Layer 树交给 Skia 或 Impeller 进行光栅化，最后显示到屏幕。

需要注意的是，`Widget` 重建不等于一定重绘。Flutter 会尽量复用 Element 和 RenderObject，真正昂贵的是布局和绘制范围过大。

示例：

```dart
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    print('build');

    return Column(
      children: [
        Text('count: $count'),
        ElevatedButton(
          onPressed: () {
            setState(() {
              count++;
            });
          },
          child: const Text('add'),
        ),
      ],
    );
  }
}
```

点击按钮后，`setState` 会标记当前 `State` 对应的 Element 需要重新 build。Flutter 不会马上同步刷新 UI，而是等到下一帧统一处理。

## 2. 如何与原生通信

Flutter 与原生通信常用 Platform Channel，主要有三种：

- `MethodChannel`：方法调用，最常用，适合 Flutter 调原生或原生调 Flutter。
- `EventChannel`：事件流，适合监听电量、传感器、定位、下载进度等连续数据。
- `BasicMessageChannel`：基础消息通信，适合自定义消息格式或双向传递字符串、二进制数据。

### MethodChannel 示例

Flutter 侧：

```dart
import 'package:flutter/services.dart';

class BatteryService {
  static const MethodChannel _channel = MethodChannel('samples/battery');

  static Future<int?> getBatteryLevel() async {
    final int? level = await _channel.invokeMethod<int>('getBatteryLevel');
    return level;
  }
}
```

Android Kotlin 侧：

```kotlin
class MainActivity : FlutterActivity() {
    private val channelName = "samples/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            if (call.method == "getBatteryLevel") {
                result.success(80)
            } else {
                result.notImplemented()
            }
        }
    }
}
```

面试时可以补充：Platform Channel 本质上是 Flutter 和宿主平台之间通过二进制消息进行通信，消息会经过序列化和反序列化，因此不适合高频、大量数据传输场景。

## 3. 如何实现国际化

Flutter 国际化的核心目标是：让同一套页面根据不同 `Locale` 展示不同语言文案。

常见方案有两种：

- 官方 `gen-l10n` + `.arb` 文件，适合正式项目。
- 手写 `AppLocalizations` + `LocalizationsDelegate`，适合理解原理和小型 Demo。

当前项目使用的是第二种方式，并把国际化逻辑抽离到了：

```text
lib/l10n/app_localizations.dart
```

### 当前项目实现步骤

1. 在 `pubspec.yaml` 中引入 `flutter_localizations`。
2. 创建 `AppLocalizations` 类，集中管理支持语言和文案表。
3. 创建 `LocalizationsDelegate`，告诉 Flutter 如何加载本地化对象。
4. 在 `MaterialApp` 中配置 `locale`、`supportedLocales`、`localizationsDelegates`。
5. 页面中通过 `context.l10n.text(key)` 读取文案。
6. 切换语言时修改 `MaterialApp.locale`，触发整棵 App 重新构建。

当前项目的核心代码：

```dart
MaterialApp(
  onGenerateTitle: (context) => context.l10n.text('appTitle'),
  locale: _locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationDelegates,
)
```

其中：

- `_locale == null`：跟随系统语言。
- `_locale == const Locale('zh')`：强制中文。
- `_locale == const Locale('en')`：强制英文。

`AppLocalizations` 中通过 Map 保存文案：

```dart
static const Map<String, Map<String, String>> _values = {
  'zh': {
    'homeTitle': 'MethodChannel 学习目录',
  },
  'en': {
    'homeTitle': 'MethodChannel Study Directory',
  },
};
```

页面使用：

```dart
Text(context.l10n.text('homeTitle'));
```

如果是带参数的文案，可以使用：

```dart
context.l10n.format('batterySuccess', {'value': batteryLevel});
```

### 面试追问 1：`supportedLocales` 有什么作用？

`supportedLocales` 用来告诉 Flutter 当前 App 支持哪些语言。

例如：

```dart
static const supportedLocales = [
  Locale('zh'),
  Locale('en'),
];
```

Flutter 会根据系统语言和这个列表做匹配，决定当前应该加载哪个本地化对象。

### 面试追问 2：`localizationsDelegates` 有什么作用？

`localizationsDelegates` 用来告诉 Flutter 如何加载不同类型的本地化资源。

当前项目里封装成：

```dart
static const List<LocalizationsDelegate<dynamic>> localizationDelegates = [
  delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
```

其中：

- `delegate` 是项目自己的文案代理。
- `GlobalMaterialLocalizations.delegate` 负责 Material 组件内置文案。
- `GlobalWidgetsLocalizations.delegate` 负责基础 Widgets 本地化。
- `GlobalCupertinoLocalizations.delegate` 负责 iOS 风格组件本地化。

### 面试追问 3：如何实现运行时语言切换？

把 `MaterialApp.locale` 绑定到状态变量。

```dart
Locale? _locale;

void _setLocale(Locale? locale) {
  setState(() {
    _locale = locale;
  });
}
```

用户选择语言时调用 `_setLocale`：

```dart
onLocaleChanged(const Locale('en'));
onLocaleChanged(const Locale('zh'));
onLocaleChanged(null); // 跟随系统
```

`setState` 后 `MaterialApp` 重新构建，页面中的 `context.l10n.text(...)` 会读取新语言文案。

### 面试追问 4：手写国际化方案和官方 gen-l10n 有什么区别？

手写方案优点：

- 容易理解原理。
- 代码集中，适合 Demo。
- 不依赖代码生成。

缺点：

- 文案多了以后 Map 会很长。
- key 写错运行时才发现。
- 复数、性别、日期格式等复杂场景不好处理。
- 翻译协作不如 `.arb` 文件方便。

正式项目更推荐官方 `gen-l10n`。

### 官方 gen-l10n 基本步骤

1. 在 `pubspec.yaml` 中引入依赖。
2. 开启 `generate: true`。
3. 添加 `l10n.yaml` 配置。
4. 创建不同语言的 `.arb` 文件。
5. 在 `MaterialApp` 中配置 `localizationsDelegates` 和 `supportedLocales`。

`pubspec.yaml` 示例：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

`l10n.yaml` 示例：

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

`lib/l10n/app_en.arb`：

```json
{
  "hello": "Hello",
  "welcome": "Welcome, {name}"
}
```

`lib/l10n/app_zh.arb`：

```json
{
  "hello": "你好",
  "welcome": "欢迎你，{name}"
}
```

使用示例：

```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const HomePage(),
);

Text(AppLocalizations.of(context)!.welcome('Tom'));
```

如果面试官继续追问，可以回答：语言切换可以通过修改 `MaterialApp` 的 `locale` 实现，并配合状态管理保存用户选择。

## 4. Flutter 中的消息队列

Flutter 使用 Dart 的事件循环机制，主要包含两个队列：

- `Microtask Queue`：微任务队列，优先级更高。
- `Event Queue`：事件队列，处理定时器、IO、用户点击、绘制事件等。

执行顺序：

1. 先执行当前同步代码。
2. 清空 Microtask Queue。
3. 从 Event Queue 中取一个事件执行。
4. 再次清空 Microtask Queue。
5. 不断循环。

示例：

```dart
import 'dart:async';

void main() {
  print('A');

  Future(() {
    print('B');
  });

  scheduleMicrotask(() {
    print('C');
  });

  Future.microtask(() {
    print('D');
  });

  print('E');
}
```

输出顺序：

```text
A
E
C
D
B
```

原因：

- `A`、`E` 是同步代码。
- `scheduleMicrotask` 和 `Future.microtask` 进入微任务队列。
- `Future(() {})` 进入事件队列。
- 微任务优先于事件任务执行。

面试重点：不要滥用微任务。如果微任务一直追加微任务，可能导致事件队列迟迟得不到执行，影响 UI 响应。

## 5. 异步的实现方式

Dart 中异步主要通过 `Future`、`async/await`、`Stream` 和 `Isolate` 实现。

### Future

`Future` 表示未来会完成的一次异步结果。

```dart
Future<String> fetchUserName() async {
  await Future.delayed(const Duration(seconds: 1));
  return 'Tom';
}
```

### async/await

`async/await` 是 Future 的语法糖，可以让异步代码写起来像同步代码。

```dart
void loadUser() async {
  try {
    final name = await fetchUserName();
    print(name);
  } catch (e) {
    print('error: $e');
  }
}
```

### Stream

`Stream` 表示多次异步结果，适合监听事件流。

```dart
Stream<int> countDown() async* {
  for (int i = 3; i >= 1; i--) {
    await Future.delayed(const Duration(seconds: 1));
    yield i;
  }
}

void listen() {
  countDown().listen((value) {
    print(value);
  });
}
```

### Isolate

Dart 是单线程事件循环模型，耗时计算会阻塞 UI。CPU 密集型任务可以放到 Isolate 中执行。

```dart
import 'package:flutter/foundation.dart';

int sum(List<int> nums) {
  return nums.fold(0, (previous, current) => previous + current);
}

Future<void> calculate() async {
  final result = await compute(sum, [1, 2, 3, 4, 5]);
  print(result);
}
```

总结：

- 网络请求、文件 IO 通常用 `Future` 和 `async/await`。
- 连续事件用 `Stream`。
- 大量计算用 `Isolate` 或 Flutter 提供的 `compute`。

## 6. setState 后的生命周期

`setState` 的作用是通知 Flutter：当前 State 的内部状态发生变化，需要重新构建 UI。

调用 `setState` 后的流程：

1. 执行 `setState` 回调中的同步代码。
2. 将当前 Element 标记为 dirty。
3. 当前同步代码执行完后，等待下一帧。
4. Flutter 调用该 State 的 `build` 方法。
5. 新旧 Widget 进行对比，更新 Element 和 RenderObject。
6. 如有需要，执行布局和绘制。

示例：

```dart
class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  int count = 0;

  @override
  void initState() {
    super.initState();
    print('initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('didChangeDependencies');
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return ElevatedButton(
      onPressed: () {
        setState(() {
          count++;
          print('setState callback');
        });
      },
      child: Text('$count'),
    );
  }
}
```

首次进入页面通常执行：

```text
initState
didChangeDependencies
build
```

点击按钮后通常执行：

```text
setState callback
build
```

注意点：

- `setState` 回调不能写成 `async`。
- `dispose` 后不能调用 `setState`，否则会报错。
- 如果异步回调中调用 `setState`，应该先判断 `mounted`。

```dart
Future<void> loadData() async {
  final data = await requestData();
  if (!mounted) return;

  setState(() {
    // update state
  });
}
```

## 7. 怎么自定义一个组件

Flutter 自定义组件通常就是封装 Widget，可以根据是否有内部状态分为：

- `StatelessWidget`：无内部可变状态。
- `StatefulWidget`：有内部可变状态。
- `InheritedWidget`：用于向子树共享数据。
- `RenderObjectWidget`：更底层的自定义布局和渲染，使用较少。

### StatelessWidget 示例

```dart
class UserAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;

  const UserAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(backgroundImage: NetworkImage(imageUrl)),
        const SizedBox(width: 8),
        Text(name),
      ],
    );
  }
}
```

### StatefulWidget 示例

```dart
class CounterButton extends StatefulWidget {
  const CounterButton({super.key});

  @override
  State<CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<CounterButton> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          count++;
        });
      },
      child: Text('count: $count'),
    );
  }
}
```

面试中可以强调：自定义组件要关注职责单一、参数清晰、状态上提、合理使用 `const`，避免组件内部承担过多业务逻辑。

## 8. pubspec.yaml 干什么的

`pubspec.yaml` 是 Dart 和 Flutter 项目的配置文件，主要作用包括：

- 配置项目名称、描述、版本号。
- 管理依赖包。
- 配置 Flutter SDK。
- 声明图片、字体、JSON 等资源文件。
- 配置代码生成、国际化等能力。

示例：

```yaml
name: demo_app
description: A Flutter demo app.
version: 1.0.0+1

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true

  assets:
    - assets/images/logo.png

  fonts:
    - family: MyFont
      fonts:
        - asset: assets/fonts/MyFont-Regular.ttf
```

说明：

- `dependencies` 是运行时依赖。
- `dev_dependencies` 是开发和测试阶段依赖。
- `assets` 声明后，资源才能通过 `Image.asset` 等方式使用。
- `version: 1.0.0+1` 中，`1.0.0` 是展示版本，`1` 是构建号。

## 9. 怎么自定义画板，继承的什么

Flutter 中自定义绘制通常使用 `CustomPaint` 和 `CustomPainter`。

- 页面中使用 `CustomPaint`。
- 自定义画笔类继承 `CustomPainter`。
- 在 `paint(Canvas canvas, Size size)` 中绘制。
- 在 `shouldRepaint` 中决定是否需要重绘。

示例：绘制一个圆形进度条。

```dart
class ProgressCircle extends StatelessWidget {
  final double progress;

  const ProgressCircle({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 120),
      painter: ProgressCirclePainter(progress),
    );
  }
}

class ProgressCirclePainter extends CustomPainter {
  final double progress;

  ProgressCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final progressPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926 / 2,
      3.1415926 * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
```

面试重点：

- 自定义画板继承 `CustomPainter`。
- 绘制 API 来自 `Canvas`。
- 画笔配置使用 `Paint`。
- `shouldRepaint` 要尽量精确，避免无意义重绘。

## 10. 如何避免重绘

避免重绘的核心思路是缩小 rebuild、layout、paint 的影响范围。

常见做法：

- 尽量使用 `const` Widget。
- 将大组件拆成小组件，避免父组件变化导致整棵子树重建。
- 使用 `RepaintBoundary` 隔离重绘区域。
- `CustomPainter.shouldRepaint` 中精确判断是否需要重绘。
- 列表使用 `ListView.builder`，避免一次性构建所有 item。
- 动画中使用 `AnimatedBuilder` 的 `child` 参数缓存不变部分。
- 使用合适的状态管理，让局部状态只影响局部 UI。
- 避免在 `build` 方法中执行耗时操作、创建复杂对象或发起网络请求。

### RepaintBoundary 示例

```dart
RepaintBoundary(
  child: CustomPaint(
    painter: ChartPainter(data),
    size: const Size(300, 200),
  ),
)
```

`RepaintBoundary` 会创建独立的 Layer。当边界外部重绘时，边界内部不一定跟着重绘；当边界内部变化时，也可以减少对外部的影响。

### AnimatedBuilder 示例

```dart
AnimatedBuilder(
  animation: animation,
  child: const Icon(Icons.favorite, size: 48),
  builder: (context, child) {
    return Transform.scale(
      scale: animation.value,
      child: child,
    );
  },
)
```

这里 `Icon` 不会在每一帧重复 build，只有外层 `Transform` 会随动画变化。

## 11. 找到一个未排序数组中的第 k 个元素

这类题目需要先确认是第 k 大还是第 k 小。常见解法有排序、堆、快速选择。

### 排序法

时间复杂度 `O(n log n)`，实现简单。

```dart
int findKthLargestBySort(List<int> nums, int k) {
  nums.sort((a, b) => b.compareTo(a));
  return nums[k - 1];
}
```

### 快速选择

快速选择平均时间复杂度 `O(n)`，最坏时间复杂度 `O(n^2)`。思想类似快速排序，每次 partition 后只递归目标所在的一侧。

示例：查找第 k 大元素。

```dart
int findKthLargest(List<int> nums, int k) {
  final target = nums.length - k;
  int left = 0;
  int right = nums.length - 1;

  while (left <= right) {
    final pivotIndex = _partition(nums, left, right);

    if (pivotIndex == target) {
      return nums[pivotIndex];
    } else if (pivotIndex < target) {
      left = pivotIndex + 1;
    } else {
      right = pivotIndex - 1;
    }
  }

  throw ArgumentError('invalid k');
}

int _partition(List<int> nums, int left, int right) {
  final pivot = nums[right];
  int storeIndex = left;

  for (int i = left; i < right; i++) {
    if (nums[i] < pivot) {
      final temp = nums[storeIndex];
      nums[storeIndex] = nums[i];
      nums[i] = temp;
      storeIndex++;
    }
  }

  final temp = nums[storeIndex];
  nums[storeIndex] = nums[right];
  nums[right] = temp;

  return storeIndex;
}
```

例如：

```dart
void main() {
  final nums = [3, 2, 1, 5, 6, 4];
  print(findKthLargest(nums, 2)); // 5
}
```

因为排序后是 `[1, 2, 3, 4, 5, 6]`，第 2 大对应下标 `length - k = 4`，结果是 `5`。

## 12. 网络请求你是用什么实现的

Flutter 中网络请求常见选择：

- `http`：官方生态常用库，轻量，适合简单请求。
- `dio`：功能更完整，适合中大型项目。
- 原生平台网络能力：通过 MethodChannel 调用原生网络库，适合已有原生网络框架或特殊安全要求。

实际项目中通常会使用 `Dio`，因为它支持拦截器、统一错误处理、取消请求、文件上传下载、超时配置等能力。

简单 Dio 封装示例：

```dart
import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  ApiClient() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer token';
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<dynamic>> getUserInfo() {
    return _dio.get('/user/info');
  }
}
```

如果项目比较简单，也可以使用 `http`：

```dart
import 'package:http/http.dart' as http;

Future<String> fetchData() async {
  final response = await http.get(Uri.parse('https://api.example.com/data'));
  if (response.statusCode == 200) {
    return response.body;
  }
  throw Exception('request failed');
}
```

## 13. Dio 比 Http 多的功能有哪些

`http` 更轻量，适合基础请求；`dio` 是更完整的网络请求库。

Dio 常见优势：

- 支持拦截器，可以统一处理 token、日志、错误、刷新登录态。
- 支持请求取消。
- 支持全局配置 baseUrl、超时时间、请求头。
- 支持文件上传和下载进度回调。
- 支持 FormData。
- 支持请求和响应转换器。
- 支持更方便的错误类型封装。
- 支持并发请求管理。
- 可以配置代理、证书校验等高级能力。

拦截器示例：

```dart
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      options.headers['token'] = 'xxx';
      handler.next(options);
    },
    onResponse: (response, handler) {
      handler.next(response);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        // handle unauthorized
      }
      handler.next(error);
    },
  ),
);
```

下载进度示例：

```dart
await dio.download(
  'https://example.com/file.zip',
  'file.zip',
  onReceiveProgress: (received, total) {
    if (total > 0) {
      print(received / total);
    }
  },
);
```

请求取消示例：

```dart
final cancelToken = CancelToken();

dio.get('/search', cancelToken: cancelToken);

cancelToken.cancel('user canceled');
```

## 14. 关于非对称加密和对称加密你知道多少

### 对称加密

对称加密指加密和解密使用同一把密钥。

特点：

- 加解密速度快。
- 适合加密大量数据。
- 密钥分发困难，一旦密钥泄露，数据就不安全。

常见算法：

- AES
- DES，已经不推荐使用
- 3DES，逐渐淘汰

示意：

```text
明文 + 密钥 -> 密文
密文 + 同一把密钥 -> 明文
```

### 非对称加密

非对称加密使用一对密钥：公钥和私钥。

常见用途：

- 公钥加密，私钥解密：保证只有私钥持有者能解密。
- 私钥签名，公钥验签：证明数据确实来自私钥持有者，并且没有被篡改。

特点：

- 安全性更适合密钥交换和身份认证。
- 计算速度比对称加密慢。
- 不适合直接加密大量数据。

常见算法：

- RSA
- ECC

示意：

```text
公钥加密 -> 私钥解密
私钥签名 -> 公钥验签
```

实际系统通常会混合使用：

1. 使用非对称加密协商或保护对称密钥。
2. 使用对称加密加密真实业务数据。

这也是 HTTPS/TLS 的核心思路之一。

## 15. HTTP 和 HTTPS 有什么不同，加密的方式有哪种

### HTTP 和 HTTPS 的区别

HTTP 是明文传输协议，HTTPS 是在 HTTP 和 TCP 之间加入 TLS/SSL 安全层后的协议。

主要区别：

- HTTP 明文传输，HTTPS 加密传输。
- HTTP 默认端口是 80，HTTPS 默认端口是 443。
- HTTPS 需要证书，用于验证服务器身份。
- HTTPS 可以防止内容被窃听、篡改，并降低中间人攻击风险。
- HTTPS 握手阶段比 HTTP 更复杂，但现代 TLS 性能已经比较成熟。

### HTTPS 的加密方式

HTTPS 不是只使用一种加密，而是组合使用多种安全机制：

- 非对称加密：用于身份认证、密钥交换或密钥协商。
- 对称加密：用于加密真正传输的数据。
- 摘要算法：用于保证数据完整性。
- 数字证书：用于证明服务器身份。

HTTPS 简化握手流程：

1. 客户端访问服务器，发送支持的 TLS 版本和加密套件。
2. 服务器返回证书和选择的加密套件。
3. 客户端校验证书是否合法，包括是否过期、域名是否匹配、是否由可信 CA 签发。
4. 双方协商出会话密钥。
5. 后续业务数据使用对称加密传输。

面试回答可以这样总结：

```text
HTTP 是明文传输，HTTPS = HTTP + TLS。
HTTPS 通过证书解决身份认证问题，通过非对称加密或密钥协商解决密钥安全交换问题，
再通过对称加密传输真实数据，同时用摘要或 MAC 机制保证完整性。
```

## 16. 如何实现多主题切换

Flutter 多主题切换的核心是控制 `MaterialApp` 的三个属性：

```dart
theme
darkTheme
themeMode
```

当前项目把主题逻辑抽离到了：

```text
lib/theme/app_theme.dart
```

页面入口在首页目录中，具体设置页是 `ThemeSettingsPage`。

### 当前项目实现思路

1. 用 `ThemeMode` 表示当前主题模式。
2. 用一个 `Color seedColor` 表示当前主题色。
3. 用 `ColorScheme.fromSeed` 生成 Material 3 色板。
4. 在 `MaterialApp` 中配置浅色主题、深色主题和当前主题模式。
5. 用户切换主题时，调用 `setState` 更新 `_themeMode` 或 `_seedColor`。
6. `MaterialApp` 重新构建，整个 App 主题更新。

核心代码：

```dart
ThemeMode _themeMode = ThemeMode.system;
Color _seedColor = AppTheme.defaultSeedColor;

MaterialApp(
  theme: AppTheme.light(_seedColor),
  darkTheme: AppTheme.dark(_seedColor),
  themeMode: _themeMode,
)
```

### 面试追问 1：`ThemeMode.system`、`ThemeMode.light`、`ThemeMode.dark` 有什么区别？

`ThemeMode.system` 表示跟随系统主题。

如果系统是浅色模式，Flutter 使用 `theme`。

如果系统是深色模式，Flutter 使用 `darkTheme`。

`ThemeMode.light` 表示强制使用浅色主题。

`ThemeMode.dark` 表示强制使用深色主题。

总结：

```text
ThemeMode.system -> 跟随系统
ThemeMode.light  -> 永远使用 theme
ThemeMode.dark   -> 永远使用 darkTheme
```

### 面试追问 2：`ColorScheme.fromSeed` 有什么作用？

`ColorScheme.fromSeed` 是 Material 3 推荐的配色生成方式。

它可以根据一个核心颜色自动推导出完整色板：

- primary
- secondary
- tertiary
- surface
- background
- error
- container 系列颜色

当前项目中：

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

深色主题只需要把 `brightness` 改成：

```dart
Brightness.dark
```

### 面试追问 3：如何实现主题色切换？

当前项目使用一个主题色列表：

```dart
static const options = [
  AppThemeOption(nameKey: 'themeColorBlue', color: Color(0xFF2563EB)),
  AppThemeOption(nameKey: 'themeColorTeal', color: Color(0xFF0F766E)),
  AppThemeOption(nameKey: 'themeColorRose', color: Color(0xFFBE123C)),
];
```

用户点击颜色选项时：

```dart
void _setSeedColor(Color seedColor) {
  setState(() {
    _seedColor = seedColor;
  });
}
```

`_seedColor` 改变后：

```dart
theme: AppTheme.light(_seedColor),
darkTheme: AppTheme.dark(_seedColor),
```

会重新生成主题，整个 App 的颜色随之变化。

### 面试追问 4：主题设置页面为什么只通过回调修改状态？

当前项目中 `ThemeSettingsPage` 接收：

```dart
final ThemeMode themeMode;
final Color seedColor;
final ValueChanged<ThemeMode> onThemeModeChanged;
final ValueChanged<Color> onSeedColorChanged;
```

它本身不保存全局主题状态，而是通过回调通知 `MyApp` 修改。

好处是：

- 全局状态集中在 `MyApp`。
- 设置页只负责展示和触发事件。
- 数据流方向清晰。
- 后续替换成 Provider、Riverpod、Bloc 时更容易。

### 面试追问 5：如何让主题选择重启后仍然生效？

当前项目的主题选择只保存在内存中，App 重启后会恢复默认值。

如果要持久化，可以使用 `shared_preferences` 保存：

```text
themeMode: system / light / dark
seedColor: 0xFF2563EB
```

启动时读取本地配置，再初始化主题状态。

基本流程：

```text
用户切换主题
        ↓
保存 themeMode 和 seedColor
        ↓
下次启动读取本地配置
        ↓
初始化 MaterialApp 的主题状态
```

### 面试追问 6：主题切换时为什么页面会自动变色？

因为页面组件大多使用的是 Theme 中的颜色，而不是写死颜色。

例如：

```dart
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surfaceContainerHighest
FilledButton
AppBar
ChoiceChip
```

当 `MaterialApp` 的主题变化时，`Theme` 这个 `InheritedWidget` 会通知下方依赖它的组件重新构建。

所以页面不需要手动逐个改颜色。

### 面试回答总结

可以这样回答：

```text
Flutter 多主题切换通常通过 MaterialApp 的 theme、darkTheme 和 themeMode 实现。
themeMode 决定使用浅色、深色还是跟随系统。
主题色可以通过 ColorScheme.fromSeed 根据 seedColor 生成完整色板。
用户切换主题时更新 ThemeMode 或 seedColor，再触发 App 重建。
为了结构清晰，可以把主题生成逻辑抽到 AppTheme 中，把设置页面通过回调通知根组件修改全局主题状态。
```

## 17. 几种状态管理的优缺点

Flutter 状态管理没有绝对最优，核心是根据状态复杂度、作用范围、团队协作方式选择合适方案。

常见分类可以这样记：

```text
页面内部简单状态 -> setState
单个响应式值 -> ValueNotifier
对象级共享状态 -> ChangeNotifier / Provider
现代依赖和异步状态 -> Riverpod
强业务流和团队规范 -> Bloc / Cubit
快速开发和响应式绑定 -> GetX
```

### 17.1 setState

`setState` 是 Flutter 原生最基础的状态管理。

实现方式：

```dart
int count = 0;

setState(() {
  count++;
});
```

优点：

- Flutter 原生支持，不需要三方库。
- 学习成本最低。
- 适合页面内部小状态。
- 代码直观，调试简单。

缺点：

- 只适合当前 `StatefulWidget` 内部。
- 不适合跨页面共享状态。
- 页面复杂后，业务逻辑容易和 UI 混在一起。
- `setState` 范围过大时，可能导致不必要的 build。

适合场景：

- 按钮展开/收起
- 当前页面计数器
- 临时 loading 状态
- 表单局部状态

面试总结：

```text
setState 适合页面内部简单状态，不适合全局状态和复杂业务状态。
```

### 17.2 ValueNotifier

`ValueNotifier` 适合管理单个值，并通过 `ValueListenableBuilder` 局部刷新 UI。

实现方式：

```dart
final count = ValueNotifier<int>(0);

ValueListenableBuilder<int>(
  valueListenable: count,
  builder: (context, value, child) {
    return Text('$value');
  },
);

count.value++;
```

优点：

- Flutter 原生能力，不需要三方库。
- 比 `setState` 更细粒度。
- 只重建监听区域。
- 适合单个简单值。

缺点：

- 只适合单值状态。
- 多字段、多业务方法时会变得混乱。
- 跨页面共享时需要自己管理对象生命周期。
- 不适合复杂异步和依赖注入场景。

适合场景：

- 计数器
- 开关状态
- 当前选中 index
- 简单输入状态

面试总结：

```text
ValueNotifier 是比 setState 更细粒度的原生响应式状态，适合单个简单值。
```

### 17.3 ChangeNotifier

`ChangeNotifier` 适合一个对象中管理多个字段，修改后通过 `notifyListeners()` 通知 UI。

实现方式：

```dart
class CounterModel extends ChangeNotifier {
  int count = 0;

  void increment() {
    count++;
    notifyListeners();
  }
}
```

优点：

- Flutter 原生类，理解成本低。
- 可以把多个状态和方法封装到一个对象里。
- 适合配合 Provider 使用。
- 小中型项目上手快。

缺点：

- 需要手动调用 `notifyListeners()`。
- 所有监听者都会收到通知，粒度不如 Riverpod 精细。
- 状态多了以后，类容易变成“大杂烩”。
- 异步状态、错误状态、缓存状态需要自己设计。

适合场景：

- 用户信息
- 设置项
- 简单列表状态
- 小型项目共享状态

面试总结：

```text
ChangeNotifier 适合简单对象级状态，但复杂项目中容易膨胀，通知粒度也不够细。
```

### 17.4 Provider

Provider 常用于把对象暴露给 Widget 树，让子组件读取或监听。

典型用法：

```dart
ChangeNotifierProvider(
  create: (_) => CounterModel(),
  child: const MyApp(),
);
```

读取：

```dart
context.watch<CounterModel>();
context.read<CounterModel>();
```

优点：

- Flutter 社区经典方案。
- 适合学习 `InheritedWidget` 和依赖注入思想。
- 与 `ChangeNotifier` 搭配简单。
- 对小中型项目足够。

缺点：

- 依赖 `BuildContext`。
- Provider 嵌套多时结构不够清晰。
- 异步状态表达不如 Riverpod。
- 类型和依赖关系不如 Riverpod 明确。

适合场景：

- 小中型项目
- 简单全局状态
- 传统 `ChangeNotifier` 架构

面试总结：

```text
Provider 是经典状态共享方案，适合简单共享状态，但复杂异步和依赖关系下 Riverpod 更清晰。
```

### 17.5 Riverpod

Riverpod 可以理解为 Provider 思路的升级版，既能做状态管理，也能做依赖注入。

实现方式：

```dart
final counterProvider = StateProvider<int>((ref) => 0);

final count = ref.watch(counterProvider);

ref.read(counterProvider.notifier).state++;
```

复杂状态：

```dart
final todoProvider =
    NotifierProvider<TodoNotifier, List<String>>(TodoNotifier.new);
```

优点：

- 不依赖 `BuildContext`。
- 依赖关系更清晰。
- 更容易测试。
- 对异步状态支持好，例如 `FutureProvider`、`AsyncNotifierProvider`。
- 可以管理 Service、Repository、缓存、全局状态。
- 适合中大型新项目。

缺点：

- 概念比 Provider 多。
- 初学需要理解 `ProviderScope`、`ref.watch`、`ref.read`、provider 生命周期。
- 如果团队没有统一规范，也可能写得分散。

适合场景：

- 新项目
- 中大型项目
- 接口请求状态
- 全局配置
- 依赖注入
- 可测试业务状态

面试总结：

```text
Riverpod 不依赖 BuildContext，能统一管理状态和依赖，尤其适合异步状态和中大型项目。
```

### 17.6 Bloc / Cubit

Bloc / Cubit 强调清晰的数据流和业务状态建模。

Cubit 示例：

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
}
```

Bloc 示例：

```dart
bloc.add(CounterIncrementPressed());
```

优点：

- 结构规范。
- 状态流清晰。
- 非常适合复杂业务。
- 非常适合团队协作。
- 测试友好。
- Event -> State 的模型适合面试表达。

缺点：

- 样板代码多。
- 简单功能写起来偏重。
- 学习成本高于 Provider / Riverpod。
- 需要团队遵守统一分层，否则也会变乱。

适合场景：

- 企业项目
- 复杂业务流程
- 强状态流要求
- 多人协作项目
- 需要严格测试的业务模块

面试总结：

```text
Bloc / Cubit 适合复杂业务流和团队协作，优点是规范和可测试，缺点是样板代码多。
```

### 17.7 GetX

GetX 是一个功能很全的工具库，包含：

- 状态管理
- 路由
- 依赖注入
- 国际化
- 弹窗、Snackbar 等工具

常见响应式写法：

```dart
final count = 0.obs;

Obx(() {
  return Text('${controller.count.value}');
});
```

常见简单更新写法：

```dart
GetBuilder<CounterController>(
  builder: (controller) {
    return Text('${controller.count}');
  },
);
```

优点：

- 上手快。
- 代码量少。
- 响应式写法直观。
- 路由、依赖注入、状态管理一套都能做。
- 适合快速开发和小团队项目。

缺点：

- 功能太集中，容易形成强耦合。
- 全局访问太方便，容易滥用。
- 大项目中状态来源可能不清晰。
- 如果到处使用 `.obs` 和 `Obx`，重建范围和依赖关系容易混乱。
- 测试和长期维护不如 Riverpod / Bloc 清晰。

面试总结：

```text
GetX 优点是开发效率高，缺点是容易全局耦合。小项目很方便，大项目要控制使用边界。
```

### 17.8 GetX 中 Obx 的优点和缺点

`Obx` 是 GetX 的响应式 Widget。

实现方式：

```dart
class CounterController extends GetxController {
  final count = 0.obs;
}

Obx(() {
  return Text('${controller.count.value}');
});
```

优点：

- 写法非常简单。
- 状态变化后自动刷新 UI。
- 不需要手动调用 `update()`。
- 适合局部、小范围响应式 UI。
- 多个 `.obs` 可以组合在同一个 `Obx` 中读取。

缺点：

- `Obx` 中读取了哪些响应式变量，决定了它依赖哪些状态，依赖关系可能不够显式。
- 如果 `Obx` 包裹范围太大，会导致较大 UI 区域重建。
- 过度使用 `.obs` 容易让状态分散。
- 对复杂业务流程，单纯靠 `Obx` 容易缺少清晰分层。
- 调试大项目时，状态来源可能不如 Riverpod / Bloc 清楚。

推荐使用场景：

- 小范围局部刷新
- 计数器
- 开关
- 输入状态
- 页面中某个独立区域的响应式展示

不推荐：

- 用一个大 `Obx` 包住整个页面
- Controller 里所有字段都 `.obs`
- 把业务流程都塞进 UI 响应式变量

### 17.9 GetX 中 GetBuilder 的优点和缺点

`GetBuilder` 是 GetX 中更接近手动刷新的一种方式。

实现方式：

```dart
class CounterController extends GetxController {
  int count = 0;

  void increment() {
    count++;
    update();
  }
}

GetBuilder<CounterController>(
  builder: (controller) {
    return Text('${controller.count}');
  },
);
```

优点：

- 不需要 `.obs`。
- 控制更明确，调用 `update()` 才刷新。
- 性能可控。
- 适合简单页面状态。
- 可以通过 `id` 精准刷新某一块 UI。

缺点：

- 需要手动调用 `update()`。
- 忘记调用 `update()`，UI 不会刷新。
- 响应式体验不如 `Obx` 自动。
- 复杂状态下也需要合理拆分 Controller。

适合场景：

- 表单页面
- 简单页面刷新
- 不需要高频响应式的状态
- 希望明确控制刷新时机的 UI

### 17.10 GetX 中应该怎么用更规范？

如果项目使用 GetX，更规范的做法是：

1. Controller 只管理当前业务模块，不要写成全局万能 Controller。
2. 简单局部响应式状态用 `Obx`。
3. 明确刷新时机、低频更新用 `GetBuilder`。
4. 不要用一个大 `Obx` 包住整个页面。
5. 不要所有字段都声明成 `.obs`。
6. 业务逻辑放 Controller，UI 只负责展示。
7. 接口请求、缓存、数据转换尽量抽到 Repository / Service。
8. Controller 生命周期要明确，避免随意 `Get.put` 全局常驻。

推荐结构：

```text
feature/
  controller/
    user_controller.dart
  repository/
    user_repository.dart
  page/
    user_page.dart
  widgets/
    user_card.dart
```

更规范的 GetX 使用建议：

```text
Obx：用于小范围、自动响应式刷新。
GetBuilder：用于明确手动刷新、低频变化区域。
Controller：只放页面或模块状态，不要承担网络层、缓存层全部职责。
Repository：负责数据来源，例如接口、本地缓存、MethodChannel。
```

### 17.11 面试中如何回答状态管理选择？

可以这样回答：

```text
如果是页面内部小状态，我用 setState。
如果只是单个值变化，我可以用 ValueNotifier。
如果是简单对象状态，可以用 ChangeNotifier 或 Provider。
如果是新项目，并且有较多异步请求、依赖注入和全局状态，我更推荐 Riverpod。
如果是复杂企业业务流，团队强调事件和状态规范，我会考虑 Bloc / Cubit。
如果项目已经使用 GetX，我会控制 Obx 的范围，简单响应式用 Obx，明确刷新用 GetBuilder，并把网络和缓存逻辑抽到 Repository，避免 Controller 过重。
```

## 18. MVC、MVVM、MVP 架构有什么区别

MVC、MVVM、MVP 都是为了做一件事：

```text
拆分 UI、业务逻辑、数据逻辑，降低耦合，提高可维护性和可测试性。
```

它们的核心区别在于：

```text
谁负责处理用户行为？
谁负责维护页面状态？
View 和业务逻辑之间如何通信？
```

### 18.1 MVC

MVC = Model + View + Controller。

结构：

```text
Model      数据模型、业务数据
View       页面 UI
Controller 接收用户操作，处理业务逻辑，更新 Model 或通知 View
```

在 Flutter 中可以这样对应：

```text
Model       User、Article、ThemeState
View        Widget 页面
Controller  GetX Controller、普通 Controller 类
```

目录示例：

```text
lib/
  features/
    user/
      model/
        user.dart
      view/
        user_page.dart
      controller/
        user_controller.dart
```

简单示例：

```dart
class User {
  const User({
    required this.name,
  });

  final String name;
}

class UserController {
  User user = const User(name: 'Tom');

  void updateName(String name) {
    user = User(name: name);
  }
}
```

优点：

- 结构简单，容易理解。
- 上手快，适合小项目。
- 很多传统 Android / iOS / Web 项目都能看到类似思想。
- GetX 项目中经常使用 Controller 管理页面逻辑，接近 MVC 思路。

缺点：

- Controller 容易变胖。
- 页面逻辑、业务逻辑、网络请求可能都堆进 Controller。
- View 和 Controller 边界如果不清晰，后期维护成本高。
- 在 Flutter 声明式 UI 中，传统 MVC 的 View 更新方式不一定最自然。

适合场景：

- 小项目
- Demo
- 后台管理页面
- 业务逻辑不复杂的 GetX 项目

不适合场景：

- 大型复杂业务
- 强测试要求项目
- 多人长期维护项目

面试总结：

```text
MVC 的优点是简单直观，缺点是 Controller 容易膨胀。Flutter 中可以用 Widget 作为 View，Controller 处理用户行为和业务逻辑，但复杂项目要避免 Controller 变成万能类。
```

### 18.2 MVVM

MVVM = Model + View + ViewModel。

结构：

```text
Model      数据模型、数据来源
View       页面 UI
ViewModel 维护页面状态，处理页面逻辑，给 View 暴露可观察状态
```

在 Flutter 中可以这样对应：

```text
Model      User、Todo、ThemeState
View       Widget 页面
ViewModel  ChangeNotifier、Riverpod Notifier、Cubit
```

目录示例：

```text
lib/
  features/
    user/
      model/
        user.dart
      view/
        user_page.dart
      view_model/
        user_view_model.dart
      repository/
        user_repository.dart
```

简单示例：

```dart
class UserViewModel extends ChangeNotifier {
  User? user;
  bool isLoading = false;

  Future<void> loadUser() async {
    isLoading = true;
    notifyListeners();

    user = const User(name: 'Tom');

    isLoading = false;
    notifyListeners();
  }
}
```

如果用 Riverpod，可以这样理解：

```dart
class UserNotifier extends Notifier<User?> {
  @override
  User? build() {
    return null;
  }

  void updateUser(User user) {
    state = user;
  }
}
```

优点：

- UI 和状态逻辑分离。
- ViewModel 更适合管理页面状态。
- 非常适合 Flutter 的声明式 UI。
- 配合 Provider、Riverpod、Cubit 都很自然。
- 可测试性比 MVC 更好。
- 页面复杂时结构更清晰。

缺点：

- 文件数量比 MVC 多。
- 小页面可能显得偏重。
- ViewModel 如果不拆分，也可能变胖。
- 需要团队约定 ViewModel 和 Repository 的边界。

适合场景：

- 中小型 Flutter 项目
- 页面状态较多的项目
- 需要可测试性的页面
- Riverpod / Provider / Cubit 项目

不适合场景：

- 极小 Demo
- 没有明显状态逻辑的静态页面

面试总结：

```text
MVVM 更适合 Flutter，因为 Flutter 是声明式 UI，View 可以监听 ViewModel 的状态变化自动重建。ViewModel 负责状态和页面逻辑，View 只负责展示，因此可维护性和可测试性更好。
```

### 18.3 MVP

MVP = Model + View + Presenter。

结构：

```text
Model      数据模型、数据来源
View       页面接口，只负责展示
Presenter 处理业务逻辑，主动调用 View 接口更新 UI
```

传统 MVP 通常会定义 View 接口：

```dart
abstract class UserView {
  void showLoading();
  void showUser(User user);
  void showError(String message);
}
```

Presenter：

```dart
class UserPresenter {
  UserPresenter(this.view);

  final UserView view;

  Future<void> loadUser() async {
    view.showLoading();
    try {
      final user = const User(name: 'Tom');
      view.showUser(user);
    } catch (error) {
      view.showError('$error');
    }
  }
}
```

在 Flutter 中，MVP 使用得相对少。

原因是 Flutter 是声明式 UI，通常更推荐：

```text
状态变化 -> Widget 重新 build
```

而 MVP 更偏传统命令式 UI：

```text
Presenter 主动调用 View.showXxx()
```

优点：

- View 和业务逻辑分离明显。
- Presenter 可以单元测试。
- 适合传统命令式 UI 框架。

缺点：

- Flutter 中不够自然。
- 需要定义 View 接口，代码偏繁琐。
- Presenter 持有 View，生命周期处理不好容易出问题。
- 页面状态复杂时，手动调用 `showLoading`、`showUser`、`showError` 会变得啰嗦。

适合场景：

- 传统 Android / iOS 迁移思路
- 强接口隔离的项目
- 对命令式 UI 更新模型更熟悉的团队

不适合场景：

- 大多数 Flutter 新项目
- 声明式状态驱动 UI 的项目

面试总结：

```text
MVP 的 Presenter 负责业务逻辑，并通过 View 接口主动更新 UI。它在传统客户端中常见，但 Flutter 更适合状态驱动 UI，所以现在 Flutter 项目里 MVP 不如 MVVM、Bloc、Riverpod 常见。
```

### 18.4 MVC、MVVM、MVP 对比

| 架构 | View 负责什么 | 逻辑放哪里 | UI 如何更新 | Flutter 推荐程度 |
|---|---|---|---|---|
| MVC | 展示 UI | Controller | Controller 修改状态后通知 UI | 一般 |
| MVVM | 展示 UI，监听状态 | ViewModel | 状态变化后 View 自动重建 | 高 |
| MVP | 实现 View 接口 | Presenter | Presenter 主动调用 View 方法 | 较低 |

更简单地记：

```text
MVC：Controller 控制页面逻辑。
MVVM：ViewModel 暴露状态，View 监听状态。
MVP：Presenter 调用 View 接口更新 UI。
```

### 18.5 Flutter 中更推荐哪个？

Flutter 更推荐 MVVM 思路。

原因：

- Flutter 是声明式 UI。
- 页面更适合根据状态自动 build。
- ViewModel / Notifier / Cubit 都能很好表达页面状态。
- 可测试性更好。
- 和 Riverpod、Provider、Bloc/Cubit 都能自然结合。

推荐组合：

```text
小项目：
Feature-first + 简单 MVVM

中大型项目：
Feature-first + MVVM + Riverpod

复杂企业项目：
Feature-first + Clean Architecture + Bloc / Cubit
```

### 18.6 面试中怎么回答

可以这样回答：

```text
MVC、MVVM、MVP 都是为了解耦 UI、状态和业务逻辑。
MVC 中 Controller 处理用户行为和业务逻辑，优点是简单，缺点是 Controller 容易膨胀。
MVVM 中 ViewModel 维护页面状态，View 监听状态变化自动更新，更适合 Flutter 的声明式 UI。
MVP 中 Presenter 处理逻辑并主动调用 View 接口更新 UI，它在传统客户端中常见，但 Flutter 中使用相对少。
实际 Flutter 项目里，我更推荐 Feature-first + MVVM，再结合 Riverpod、Provider 或 Cubit 管理状态。
```
