import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rabbit_mq/rabbit_mq.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String exchange = 'test';
  String routingKey = 'test';

  late StreamSubscription _receiveSubscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    // 初始化监听
    _initStreamListener();
  }

  // 初始化消息监听
  void _initStreamListener() {
    _receiveSubscription = RabbitMq.receiveStream.listen((event) {
      print("✅ 收到MQ数据：${event.toString()}");
    });
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await RabbitMq.platformVersion ?? 'Unknown platform version';
      print("✅ 平台版本：$platformVersion");
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;
    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> connect() async {
    print("🔗 开始执行连接操作...");

    try {
      bool? connectResult = await RabbitMq.connect(
        '10.8.0.13',
        'admin',
        'admin123',
        5,
      );
      print("✅ 连接结果：$connectResult");

      if (connectResult == true) {
        await RabbitMq.createQueue(exchange, routingKey, 'test2', true, true);
        print("✅ 创建队列成功");

        await RabbitMq.listenQueue('MES.EmployeeHoursData');
        await RabbitMq.listenQueue('test1');
        print("✅ 开始监听队列");
      } else {
        print("❌ 连接失败");
      }
    } catch (e) {
      print("❌ connect 异常：$e");
    }
  }

  // 发送消息
  Future<void> publish() async {
    print("📤 发送消息...");
    try {
      final result = await RabbitMq.publish(
        exchange,
        routingKey,
        json.encode({'a': 1}),
      );
      print("✅ 发送结果：$result");
    } catch (e) {
      print("❌ 发送异常：$e");
    }
  }

  @override
  void dispose() {
    // 取消监听
    _receiveSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: connect,
                child: const Text('连接'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: publish,
                child: const Text('发送消息'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}