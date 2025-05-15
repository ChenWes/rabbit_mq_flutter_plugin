import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'rabbit_mq_flutter_plugin_platform_interface.dart';

/// An implementation of [RabbitMqFlutterPluginPlatform] that uses method channels.
class MethodChannelRabbitMqFlutterPlugin extends RabbitMqFlutterPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rabbit_mq_flutter_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
