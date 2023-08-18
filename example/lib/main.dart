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

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await RabbitMq.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  connect() async {
    bool? a = await RabbitMq.connect('10.8.0.2', 'admin', 'admin123', 5);
    RabbitMq.listenQueue('test');
    RabbitMq.listenQueue('test1');
    RabbitMq.createQueue(exchange, routingKey, 'test2', true, true);
    RabbitMq.receiveStream.listen((event) {
      print("返回的数据" + event.toString());
    });
  }

  publish() {
    RabbitMq.publish(exchange, routingKey, json.encode({'a': 1}));
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
              ElevatedButton(onPressed: connect, child: Text('连接')),
              ElevatedButton(onPressed: publish, child: Text('发送消息')),
            ],
          ),
        ),
      ),
    );
  }
}
