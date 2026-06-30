import 'package:flutter/material.dart';

import 'state_learning_widgets.dart';

class BlocCubitNotes extends StatelessWidget {
  const BlocCubitNotes({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        LearningSection(
          title: '为什么 Riverpod 后再学 Bloc / Cubit',
          description:
              'Bloc / Cubit 更强调业务流规范，适合多人协作和复杂业务。它比 Riverpod 更严格，但样板代码也更多。',
          child: StateCodeBlock(
            code: """// Cubit 的核心思想
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
}""",
          ),
        ),
        LearningSection(
          title: 'Cubit 和 Bloc 的区别',
          description:
              'Cubit 直接调用方法修改状态；Bloc 通过 Event 输入，再由事件处理器产出 State。Cubit 更轻，Bloc 更适合复杂业务流。',
          child: StateCodeBlock(
            code: """// Cubit：方法 -> 状态
cubit.increment();

// Bloc：事件 -> 状态
bloc.add(CounterIncrementPressed());""",
          ),
        ),
        LearningSection(
          title: '面试回答重点',
          description:
              '小功能可用 setState / ValueNotifier；中大型新项目推荐 Riverpod；强流程、强规范团队常用 Bloc / Cubit。',
          child: StateCodeBlock(
            code: """状态管理选择：
1. 页面内部小状态：setState
2. 单值监听：ValueNotifier
3. 简单共享状态：ChangeNotifier / Provider
4. 新项目、异步和依赖管理：Riverpod
5. 企业复杂业务流：Bloc / Cubit""",
          ),
        ),
      ],
    );
  }
}
