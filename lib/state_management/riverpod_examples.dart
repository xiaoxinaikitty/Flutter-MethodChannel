import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state_learning_widgets.dart';

/// Provider：只读依赖示例。
///
/// 适合保存不会被页面直接修改的依赖，例如配置、Repository、Service。
final appNameProvider = Provider<String>((ref) {
  return 'MethodChannel 状态管理学习';
});

/// StateProvider：简单可变状态示例。
///
/// 适合计数器、开关、筛选条件这类“只有一个值”的简单状态。
final riverpodCounterProvider = StateProvider<int>((ref) {
  return 0;
});

/// FutureProvider：异步状态示例。
///
/// 适合接口请求、本地缓存读取、MethodChannel 异步调用。
final asyncMessageProvider = FutureProvider<String>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 350));
  return 'FutureProvider 已完成一次模拟异步请求';
});

/// NotifierProvider：复杂状态示例。
///
/// TodoListNotifier 负责修改状态，`List<String>` 是 UI 读取到的状态。
final todoListProvider =
    NotifierProvider<TodoListNotifier, List<String>>(TodoListNotifier.new);

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

    /// 注意：不要直接 state.add(value)。
    ///
    /// Riverpod 推荐不可变状态，创建新 List 替换旧 List，
    /// UI 才能稳定感知状态变化。
    state = [...state, value];
  }

  void remove(String value) {
    state = [
      for (final item in state)
        if (item != value) item,
    ];
  }
}

/// 一个更接近真实项目的状态模型。
///
/// 这里模拟 App 设置状态：语言、主题模式、主题色。
class DemoSettingsState {
  const DemoSettingsState({
    required this.language,
    required this.themeMode,
    required this.seedColor,
  });

  final String language;
  final ThemeMode themeMode;
  final Color seedColor;

  DemoSettingsState copyWith({
    String? language,
    ThemeMode? themeMode,
    Color? seedColor,
  }) {
    return DemoSettingsState(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}

final demoSettingsProvider =
    NotifierProvider<DemoSettingsNotifier, DemoSettingsState>(
  DemoSettingsNotifier.new,
);

class DemoSettingsNotifier extends Notifier<DemoSettingsState> {
  @override
  DemoSettingsState build() {
    return const DemoSettingsState(
      language: '中文',
      themeMode: ThemeMode.system,
      seedColor: Color(0xFF2563EB),
    );
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void setThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }

  void setSeedColor(Color seedColor) {
    state = state.copyWith(seedColor: seedColor);
  }
}

class RiverpodExamples extends ConsumerStatefulWidget {
  const RiverpodExamples({super.key});

  @override
  ConsumerState<RiverpodExamples> createState() => _RiverpodExamplesState();
}

class _RiverpodExamplesState extends ConsumerState<RiverpodExamples> {
  final TextEditingController _todoController = TextEditingController();

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appName = ref.watch(appNameProvider);
    final counter = ref.watch(riverpodCounterProvider);
    final asyncMessage = ref.watch(asyncMessageProvider);
    final todos = ref.watch(todoListProvider);
    final settings = ref.watch(demoSettingsProvider);

    /// ref.listen 用于处理副作用。
    ///
    /// 例如弹 SnackBar、页面跳转、打点日志。
    /// 它不应该用来直接构建 UI，构建 UI 应该使用 ref.watch。
    ref.listen<int>(riverpodCounterProvider, (previous, next) {
      print('从 $previous 变成 $next');
      if (next == 3 && previous != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ref.listen 监听到计数变成 3')),
        );
      }
    });

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LearningSection(
          title: 'Provider：只读依赖',
          description: '定义一个不会被页面直接修改的依赖，页面通过 ref.watch 读取。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前读取到的 appName：$appName'),
              const SizedBox(height: 12),
              const StateCodeBlock(
                code: """// 1. 定义状态
final appNameProvider = Provider<String>((ref) {
  return 'MethodChannel 状态管理学习';
});

// 2. 页面中使用
final appName = ref.watch(appNameProvider);

// 注意：
// Provider 通常用于只读依赖，例如配置、Repository、Service。
// 如果需要修改状态，不要用 Provider，应该使用 StateProvider 或 NotifierProvider。""",
              ),
            ],
          ),
        ),
        LearningSection(
          title: 'StateProvider：简单可变状态',
          description: '定义一个简单计数状态，按钮点击时通过 ref.read 修改。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('当前计数：$counter')),
                  FilledButton(
                    onPressed: () {
                      ref.read(riverpodCounterProvider.notifier).state++;
                    },
                    child: const Text('增加'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(riverpodCounterProvider.notifier).state = 0;
                    },
                    child: const Text('重置'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const StateCodeBlock(
                code: """// 1. 定义状态
final counterProvider = StateProvider<int>((ref) {
  return 0;
});

// 2. 监听状态，状态变化时当前 Widget 会重建
final count = ref.watch(counterProvider);

// 3. 修改状态，常用于按钮点击事件
ref.read(counterProvider.notifier).state++;

// 注意：
// StateProvider 只适合简单状态。
// 如果状态修改逻辑变多，应该升级为 NotifierProvider。""",
              ),
            ],
          ),
        ),
        LearningSection(
          title: 'NotifierProvider：封装业务逻辑',
          description: '把状态和修改状态的方法放到 Notifier 中，页面只调用方法，不直接处理业务细节。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _todoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '新增学习任务',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(todoListProvider.notifier)
                          .add(_todoController.text);
                      _todoController.clear();
                    },
                    child: const Text('添加'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final todo in todos)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(todo),
                  trailing: IconButton(
                    tooltip: '删除',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      ref.read(todoListProvider.notifier).remove(todo);
                    },
                  ),
                ),
              const SizedBox(height: 12),
              const StateCodeBlock(
                code: """// 1. 定义 provider
final todoListProvider =
    NotifierProvider<TodoListNotifier, List<String>>(TodoListNotifier.new);

// 2. 定义 Notifier
class TodoListNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ['阅读 Riverpod 基础概念'];
  }

  void add(String text) {
    final value = text.trim();
    if (value.isEmpty) return;

    // 不要直接修改原 List，要创建新 List。
    state = [...state, value];
  }
}

// 3. 页面监听
final todos = ref.watch(todoListProvider);

// 4. 页面触发操作
ref.read(todoListProvider.notifier).add('学习 NotifierProvider');""",
              ),
            ],
          ),
        ),
        LearningSection(
          title: 'FutureProvider：异步状态',
          description: '把异步过程拆成 loading / data / error，避免页面自己维护多个状态变量。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              asyncMessage.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text('请求失败：$error'),
                data: (message) => Row(
                  children: [
                    Expanded(child: Text(message)),
                    OutlinedButton(
                      onPressed: () {
                        ref.invalidate(asyncMessageProvider);
                      },
                      child: const Text('重新请求'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const StateCodeBlock(
                code: """// 1. 定义异步状态
final asyncMessageProvider = FutureProvider<String>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 350));
  return '请求完成';
});

// 2. 页面监听 AsyncValue
final asyncMessage = ref.watch(asyncMessageProvider);

// 3. 处理 loading / error / data
asyncMessage.when(
  loading: () => const CircularProgressIndicator(),
  error: (error, stackTrace) => Text('失败：\$error'),
  data: (message) => Text(message),
);

// 4. 重新请求
ref.invalidate(asyncMessageProvider);""",
              ),
            ],
          ),
        ),
        LearningSection(
          title: '完整示例：AppSettingsState + NotifierProvider',
          description:
              '这个示例模拟真实项目中的全局设置状态：语言、主题模式、主题色。重点观察“状态模型 + Notifier + Provider + 页面使用”。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前语言：${settings.language}'),
              Text('当前主题模式：${settings.themeMode.name}'),
              Row(
                children: [
                  const Text('当前主题色：'),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: settings.seedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(demoSettingsProvider.notifier)
                          .setLanguage('English');
                    },
                    child: const Text('切英文'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      ref
                          .read(demoSettingsProvider.notifier)
                          .setThemeMode(ThemeMode.dark);
                    },
                    child: const Text('深色'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      ref
                          .read(demoSettingsProvider.notifier)
                          .setSeedColor(const Color(0xFFBE123C));
                    },
                    child: const Text('玫红主题'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const StateCodeBlock(
                code: """// 1. 定义不可变状态
class AppSettingsState {
  const AppSettingsState({
    required this.language,
    required this.themeMode,
    required this.seedColor,
  });

  final String language;
  final ThemeMode themeMode;
  final Color seedColor;

  AppSettingsState copyWith({
    String? language,
    ThemeMode? themeMode,
    Color? seedColor,
  }) {
    return AppSettingsState(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}

// 2. 用 Notifier 管理状态
class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    return const AppSettingsState(
      language: '中文',
      themeMode: ThemeMode.system,
      seedColor: Color(0xFF2563EB),
    );
  }

  void setThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }
}

// 3. 暴露 provider
final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);

// 4. 页面使用
final settings = ref.watch(appSettingsProvider);
ref.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.dark);

// 注意：
// 状态类尽量不可变；修改状态时创建新对象；
// UI 只负责调用方法，不要把业务逻辑写在按钮里。""",
              ),
            ],
          ),
        ),
        const LearningSection(
          title: 'Riverpod 使用注意事项',
          description: '这些是项目里最容易踩坑的点。',
          child: StateCodeBlock(
            code: """1. 必须在 App 根部包 ProviderScope。
2. provider 要定义在文件顶层，不要定义在 build 方法里。
3. ref.watch 用于构建 UI，状态变化会触发重建。
4. ref.read 用于事件回调，例如按钮点击。
5. ref.listen 用于副作用，例如 SnackBar、跳转、日志。
6. List / Map 状态不要原地修改，要创建新对象。
7. StateProvider 只适合简单状态，复杂逻辑用 NotifierProvider。
8. FutureProvider 适合异步读取，但复杂异步写入可学习 AsyncNotifierProvider。
9. 不要把所有业务都写在 Widget 中，业务方法应该放到 Notifier。""",
          ),
        ),
      ],
    );
  }
}
