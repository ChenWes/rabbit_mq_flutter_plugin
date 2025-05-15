import 'package:flutter_test/flutter_test.dart';
import 'package:rabbit_mq_flutter_plugin/rabbit_mq_flutter_plugin.dart';
import 'package:rabbit_mq_flutter_plugin/rabbit_mq_flutter_plugin_platform_interface.dart';
import 'package:rabbit_mq_flutter_plugin/rabbit_mq_flutter_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRabbitMqFlutterPluginPlatform
    with MockPlatformInterfaceMixin
    implements RabbitMqFlutterPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final RabbitMqFlutterPluginPlatform initialPlatform = RabbitMqFlutterPluginPlatform.instance;

  test('$MethodChannelRabbitMqFlutterPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRabbitMqFlutterPlugin>());
  });

  test('getPlatformVersion', () async {
    RabbitMqFlutterPlugin rabbitMqFlutterPlugin = RabbitMqFlutterPlugin();
    MockRabbitMqFlutterPluginPlatform fakePlatform = MockRabbitMqFlutterPluginPlatform();
    RabbitMqFlutterPluginPlatform.instance = fakePlatform;

    //expect(await rabbitMqFlutterPlugin.getPlatformVersion(), '42');
  });
}
