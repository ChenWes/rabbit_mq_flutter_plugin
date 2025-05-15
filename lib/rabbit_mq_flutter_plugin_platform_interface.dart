import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rabbit_mq_flutter_plugin_method_channel.dart';

abstract class RabbitMqFlutterPluginPlatform extends PlatformInterface {
  /// Constructs a RabbitMqFlutterPluginPlatform.
  RabbitMqFlutterPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static RabbitMqFlutterPluginPlatform _instance = MethodChannelRabbitMqFlutterPlugin();

  /// The default instance of [RabbitMqFlutterPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelRabbitMqFlutterPlugin].
  static RabbitMqFlutterPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RabbitMqFlutterPluginPlatform] when
  /// they register themselves.
  static set instance(RabbitMqFlutterPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
