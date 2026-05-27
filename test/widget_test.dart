import 'package:flutter_test/flutter_test.dart';

import 'package:channel/main.dart';

void main() {
  testWidgets('shows MethodChannel demo page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('MethodChannel 入门示例'), findsOneWidget);
    expect(find.text('获取原生电量'), findsOneWidget);
    expect(find.text('获取设备型号'), findsOneWidget);
    expect(find.text('把名字传给原生'), findsOneWidget);
    expect(find.text('打开系统相机'), findsOneWidget);
    expect(find.textContaining('MethodChannel 调用多个原生能力'), findsOneWidget);
  });
}
