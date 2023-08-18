import 'dart:async';

import 'package:flutter/services.dart';

class RabbitMq {
  static const MethodChannel _channel = MethodChannel('rabbit_mq');
  static const EventChannel _eventChannel = EventChannel('rabbit_mq/event');
  static const EventChannel _publishEventChannel =
      EventChannel('rabbit_mq/publishEvent');
  static const EventChannel _publishFailEventChannel =
      EventChannel('rabbit_mq/publishFailEvent');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// 连接mq
  static Future<bool?> connect(
      String host, String userName, String password, int heartbeat) async {
    final bool? result = await _channel.invokeMethod('connect', {
      'host': host,
      'userName': userName,
      'password': password,
      'heartbeat': heartbeat
    });
    return result;
  }

  static Future<String?> createQueue(String exchange, String routingKey,
      String queue, bool exchangeDurable, bool queueDurable) async {
    final String? result = await _channel.invokeMethod('createQueue', {
      'exchange': exchange,
      'routingKey': routingKey,
      'queue': queue,
      'exchangeDurable': exchangeDurable,
      'queueDurable': queueDurable
    });
    return result;
  }

  /// 发送消息
  static Future<bool?> publish(
      String exchange, String routingKey, String message) async {
    final bool? result = await _channel.invokeMethod('publish',
        {'exchange': exchange, 'routingKey': routingKey, 'message': message});
    return result;
  }

  /// 监听队列
  static Future<String?> listenQueue(String queueName) async {
    final String? result =
        await _channel.invokeMethod('listenQueue', {'queueName': queueName});
    return result;
  }

  /// Stream(Event) coming from Android
  /// 调用数据流
  static Stream get receiveStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map<dynamic>((dynamic value) => value);
  }

  ///接收发送成功的消息
  static Stream get receivePublishEventStream {
    return _publishEventChannel
        .receiveBroadcastStream()
        .map<dynamic>((dynamic value) => value);
  }

  ///接收发送失败的消息
  static Stream get receivePublishFailEventStream {
    return _publishFailEventChannel
        .receiveBroadcastStream()
        .map<dynamic>((dynamic value) => value);
  }
}
