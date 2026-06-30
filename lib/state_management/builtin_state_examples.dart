import 'package:flutter/material.dart';

import 'state_learning_widgets.dart';

class BuiltInStateExamples extends StatefulWidget {
  const BuiltInStateExamples({super.key});

  @override
  State<BuiltInStateExamples> createState() => _BuiltInStateExamplesState();
}

class _BuiltInStateExamplesState extends State<BuiltInStateExamples> {
  int _setStateCount = 0;
  final ValueNotifier<int> _valueNotifierCount = ValueNotifier<int>(0);
  final CounterChangeNotifier _changeNotifier = CounterChangeNotifier();

  @override
  void dispose() {
    _valueNotifierCount.dispose();
    _changeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LearningSection(
          title: 'setState',
          description: '适合页面内部的小状态。调用 setState 后，当前 State 对应的子树会重新 build。',
          child: Row(
            children: [
              Expanded(child: Text('当前计数：$_setStateCount')),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _setStateCount++;
                  });
                },
                child: const Text('增加'),
              ),
            ],
          ),
        ),
        LearningSection(
          title: 'ValueNotifier',
          description: '适合单个值的轻量响应式状态。ValueListenableBuilder 只重建监听区域。',
          child: ValueListenableBuilder<int>(
            valueListenable: _valueNotifierCount,
            builder: (context, count, child) {
              return Row(
                children: [
                  Expanded(child: Text('当前计数：$count')),
                  FilledButton(
                    onPressed: () {
                      _valueNotifierCount.value++;
                    },
                    child: const Text('增加'),
                  ),
                ],
              );
            },
          ),
        ),
        LearningSection(
          title: 'ChangeNotifier',
          description: '适合一个对象里包含多个状态字段。修改后调用 notifyListeners 通知 UI 更新。',
          child: AnimatedBuilder(
            animation: _changeNotifier,
            builder: (context, child) {
              return Row(
                children: [
                  Expanded(child: Text('当前计数：${_changeNotifier.count}')),
                  FilledButton(
                    onPressed: _changeNotifier.increment,
                    child: const Text('增加'),
                  ),
                ],
              );
            },
          ),
        ),
        const LearningSection(
          title: '学习结论',
          description:
              '这些都是 Flutter 原生能力。学 Riverpod 前，先理解这些基础状态，有助于判断什么时候需要更强的状态管理方案。',
          child: StateCodeBlock(
            code: """// 页面内部状态
setState(() {});

// 单值监听
final count = ValueNotifier<int>(0);

// 多字段对象状态
class Counter extends ChangeNotifier {
  int count = 0;
  void increment() {
    count++;
    notifyListeners();
  }
}""",
          ),
        ),
      ],
    );
  }
}

class CounterChangeNotifier extends ChangeNotifier {
  int count = 0;

  void increment() {
    count++;
    notifyListeners();
  }
}
