import 'package:flutter/material.dart';

import 'bloc_cubit_notes.dart';
import 'builtin_state_examples.dart';
import 'riverpod_examples.dart';

class StateManagementPage extends StatelessWidget {
  const StateManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('状态管理学习'),
          backgroundColor: theme.colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(text: '原生基础'),
              Tab(text: 'Riverpod'),
              Tab(text: 'Bloc/Cubit'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BuiltInStateExamples(),
            RiverpodExamples(),
            BlocCubitNotes(),
          ],
        ),
      ),
    );
  }
}
