// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rabbit_mq/rabbit_mq.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final RabbitMq plugin = RabbitMq();
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(
      find.byWidgetPredicate(
            (Widget widget) => widget is Text &&
            widget.data!.startsWith('Running on:'),
      ),
      findsOneWidget,
    );
  });
}
