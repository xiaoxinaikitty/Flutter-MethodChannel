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

Flutter 国际化通常使用官方的 `flutter_localizations` 和 `intl`。

基本步骤：

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
