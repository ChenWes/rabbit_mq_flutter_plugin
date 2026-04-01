# RabbitMQ Flutter Plugin

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

一个为 Flutter 应用提供的 RabbitMQ 消息队列插件，支持 Android 平台。通过本插件，您可以在 Flutter 应用中轻松集成 RabbitMQ，实现可靠的消息传递功能。

## ✨ 功能特性

- ✅ **连接管理**: 支持连接 RabbitMQ 服务器
- ✅ **队列创建**: 声明交换机和队列，支持持久化配置
- ✅ **消息发布**: 向指定交换机和路由键发布消息
- ✅ **消息监听**: 监听指定队列并实时接收消息
- ✅ **事件流**: 通过 Stream 实时接收消息和发送状态
- ✅ **线程池管理**: 使用线程池处理异步操作，避免 UI 阻塞
- ✅ **自动恢复**: 支持连接和拓扑自动恢复
- ✅ **发送确认**: 支持消息发送确认机制

## 📋 系统要求

- Flutter SDK: >= 3.3.0或flutter3.41.6
- Dart SDK: ^3.11.4
- Android: minSdkVersion 24 (Android 7.0+)
- RabbitMQ 服务器: 支持 AMQP 0-9-1 协议

## 🚀 安装

### 1. 添加依赖

在您的 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  rabbit_mq: ^0.0.1
```

运行 `flutter pub get` 安装依赖。

### 2. 平台配置

#### Android 配置

确保您的 `android/app/build.gradle` 文件中已设置正确的 minSdkVersion：

```gradle
android {
    defaultConfig {
        minSdkVersion 24
    }
}
```

## 📖 使用方法

### 基本使用流程

1. **导入包**
```dart
import 'package:rabbit_mq/rabbit_mq.dart';
```

2. **连接 RabbitMQ 服务器**
```dart
bool? connected = await RabbitMq.connect(
  'your_rabbitmq_host',  // RabbitMQ 服务器地址
  'username',            // 用户名
  'password',            // 密码
  5,                     // 心跳间隔（秒）
);
```

3. **创建队列**
```dart
String? result = await RabbitMq.createQueue(
  'exchange_name',       // 交换机名称
  'routing_key',         // 路由键
  'queue_name',          // 队列名称
  true,                  // 交换机是否持久化
  true,                  // 队列是否持久化
);
```

4. **监听队列消息**
```dart
// 开始监听队列
String? listenResult = await RabbitMq.listenQueue('queue_name');

// 设置消息接收监听
StreamSubscription subscription = RabbitMq.receiveStream.listen((message) {
  print('收到消息: $message');
  // 处理接收到的消息
});
```

5. **发布消息**
```dart
bool? sent = await RabbitMq.publish(
  'exchange_name',       // 交换机名称
  'routing_key',         // 路由键
  json.encode({'key': 'value'}),  // 消息内容（JSON格式）
);
```

### 完整示例

以下是一个完整的使用示例：

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rabbit_mq/rabbit_mq.dart';

class RabbitMQExample extends StatefulWidget {
  const RabbitMQExample({super.key});

  @override
  State<RabbitMQExample> createState() => _RabbitMQExampleState();
}

class _RabbitMQExampleState extends State<RabbitMQExample> {
  late StreamSubscription _receiveSubscription;
  late StreamSubscription _publishSuccessSubscription;
  late StreamSubscription _publishFailSubscription;

  @override
  void initState() {
    super.initState();
    _initStreamListeners();
  }

  void _initStreamListeners() {
    // 监听接收到的消息
    _receiveSubscription = RabbitMq.receiveStream.listen((message) {
      print('📥 收到消息: $message');
      // 更新UI或处理消息
    });

    // 监听消息发送成功事件
    _publishSuccessSubscription = RabbitMq.receivePublishEventStream.listen((message) {
      print('✅ 消息发送成功: $message');
    });

    // 监听消息发送失败事件
    _publishFailSubscription = RabbitMq.receivePublishFailEventStream.listen((message) {
      print('❌ 消息发送失败: $message');
    });
  }

  Future<void> _connectToRabbitMQ() async {
    try {
      bool? connected = await RabbitMq.connect(
        '10.8.0.13',
        'admin',
        'admin123',
        5,
      );

      if (connected == true) {
        print('✅ 连接成功');
        
        // 创建队列
        await RabbitMq.createQueue(
          'test_exchange',
          'test_routing_key',
          'test_queue',
          true,
          true,
        );
        print('✅ 队列创建成功');
        
        // 开始监听队列
        await RabbitMq.listenQueue('test_queue');
        print('✅ 开始监听队列');
      } else {
        print('❌ 连接失败');
      }
    } catch (e) {
      print('❌ 连接异常: $e');
    }
  }

  Future<void> _publishMessage() async {
    try {
      final message = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': 'Hello RabbitMQ!',
      };
      
      final result = await RabbitMq.publish(
        'test_exchange',
        'test_routing_key',
        json.encode(message),
      );
      
      if (result == true) {
        print('📤 消息已发送');
      }
    } catch (e) {
      print('❌ 发送异常: $e');
    }
  }

  @override
  void dispose() {
    _receiveSubscription.cancel();
    _publishSuccessSubscription.cancel();
    _publishFailSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RabbitMQ 示例'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _connectToRabbitMQ,
              child: const Text('连接 RabbitMQ'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _publishMessage,
              child: const Text('发送消息'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔧 API 参考

### 静态方法

#### `connect`
```dart
static Future<bool?> connect(
  String host,
  String userName, 
  String password,
  int heartbeat,
)
```
连接到 RabbitMQ 服务器。

**参数:**
- `host`: RabbitMQ 服务器地址
- `userName`: 用户名
- `password`: 密码  
- `heartbeat`: 心跳间隔（秒）

**返回值:** `bool` - 连接是否成功

#### `createQueue`
```dart
static Future<String?> createQueue(
  String exchange,
  String routingKey,
  String queue,
  bool exchangeDurable,
  bool queueDurable,
)
```
创建队列并绑定到交换机。

**参数:**
- `exchange`: 交换机名称
- `routingKey`: 路由键
- `queue`: 队列名称
- `exchangeDurable`: 交换机是否持久化
- `queueDurable`: 队列是否持久化

**返回值:** `String` - 创建结果消息

#### `publish`
```dart
static Future<bool?> publish(
  String exchange,
  String routingKey,
  String message,
)
```
发布消息到指定交换机和路由键。

**参数:**
- `exchange`: 交换机名称
- `routingKey`: 路由键
- `message`: 消息内容（字符串格式）

**返回值:** `bool` - 发送是否成功

#### `listenQueue`
```dart
static Future<String?> listenQueue(String queueName)
```
开始监听指定队列。

**参数:**
- `queueName`: 队列名称

**返回值:** `String` - 监听结果消息

### Stream 属性

#### `receiveStream`
```dart
static Stream get receiveStream
```
接收队列消息的 Stream。当有消息到达监听的队列时，会通过此 Stream 推送。

#### `receivePublishEventStream`
```dart
static Stream get receivePublishEventStream
```
消息发送成功事件的 Stream。当消息成功发送到 RabbitMQ 时触发。

#### `receivePublishFailEventStream`
```dart
static Stream get receivePublishFailEventStream
```
消息发送失败事件的 Stream。当消息发送失败时触发。

## 🏗️ 项目结构

```
rabbit_mq/
├── android/                    # Android 平台实现
│   ├── src/main/java/cf/mes/rabbit_mq/
│   │   └── RabbitMqPlugin.java # 插件主类
│   └── build.gradle.kts        # 构建配置（包含 RabbitMQ 客户端依赖）
├── lib/                        # Dart 接口
│   ├── rabbit_mq.dart          # 主接口类
│   ├── rabbit_mq_method_channel.dart
│   └── rabbit_mq_platform_interface.dart
├── example/                    # 示例应用
│   └── lib/main.dart           # 使用示例
└── test/                       # 测试文件
```

## 🔍 技术实现细节

### Android 端实现

- **线程池管理**: 使用 `ThreadPoolExecutor` 处理所有 RabbitMQ 操作，避免阻塞 UI 线程
- **连接恢复**: 启用自动连接恢复和拓扑恢复功能
- **发送确认**: 使用 `confirmSelect()` 和 `waitForConfirms()` 确保消息可靠发送
- **事件通道**: 通过 `EventChannel` 实现 Dart 端的数据流监听

### 配置参数

- **心跳间隔**: 默认 5 秒，可根据网络状况调整
- **连接超时**: 10 秒
- **网络恢复间隔**: 10 秒
- **线程池配置**: 核心线程数 5，最大线程数 10，队列容量 100

## 🧪 运行示例

1. 进入 `example` 目录：
```bash
cd example
```

2. 运行示例应用：
```bash
flutter run
```

3. 修改示例代码中的连接参数（主机、用户名、密码）以匹配您的 RabbitMQ 服务器配置。

## 📝 注意事项

1. **Android 权限**: 确保应用具有网络访问权限
2. **连接参数**: 根据实际 RabbitMQ 服务器配置调整连接参数
3. **内存管理**: 及时取消 Stream 监听，避免内存泄漏
4. **错误处理**: 建议在生产环境中添加完善的错误处理逻辑
5. **后台运行**: 当前版本不支持后台消息接收，应用需在前台运行

## 🙏 致谢

- [RabbitMQ Java Client](https://github.com/rabbitmq/rabbitmq-java-client) - RabbitMQ 官方 Java 客户端库
- [Flutter Plugin Development](https://flutter.dev/docs/development/packages-and-plugins/developing-packages) - Flutter 插件开发文档

---

**提示**: 在使用本插件前，请确保您已了解 RabbitMQ 的基本概念和使用方法。建议参考 [RabbitMQ 官方文档](https://www.rabbitmq.com/documentation.html) 了解更多信息。