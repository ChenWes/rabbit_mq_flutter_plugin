import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'rabbit_mq_platform_interface.dart';

/// An implementation of [RabbitMqPlatform] that uses method channels.
class MethodChannelRabbitMq extends RabbitMqPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rabbit_mq');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
