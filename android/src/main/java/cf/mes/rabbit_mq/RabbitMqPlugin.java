package cf.mes.rabbit_mq;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.BuiltinExchangeType;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.Consumer;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * RabbitMqPlugin
 */
public class RabbitMqPlugin implements FlutterPlugin, MethodCallHandler{
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;

    private Channel mqChannel;
    private Connection connection;



    private Handler mHandler = new Handler(Looper.getMainLooper());

    List<String> consumerList=new ArrayList<>();

    // 事件通知
    public  EventChannel.EventSink receiveEventSink;

    //发送成功确认
    private  EventChannel.EventSink eventSink = null;

    //发送失败
    private  EventChannel.EventSink publishFailEventSink = null;

    private static final int CORE_POOL_SIZE = 5;
    private static final int MAX_POOL_SIZE = 10;
    private static final int QUEUE_CAPACITY = 100;
    private static final Long KEEP_ALIVE_TIME = 1L;

    //创建线程池
    ThreadPoolExecutor executorService = new ThreadPoolExecutor(
            CORE_POOL_SIZE,
            MAX_POOL_SIZE,
            KEEP_ALIVE_TIME,
            TimeUnit.SECONDS,
            new ArrayBlockingQueue<>(QUEUE_CAPACITY),
            new ThreadPoolExecutor.AbortPolicy());



    // 事件派发流
    private  EventChannel.StreamHandler receiveHandler = new  EventChannel.StreamHandler(){

        @Override

        public void onListen(Object arguments, EventChannel.EventSink events) {

            receiveEventSink = events;

        }


        @Override

        public void onCancel(Object arguments) {

            receiveEventSink = null;

        }

    };

    // 事件派发流
    private  EventChannel.StreamHandler streamHandler = new  EventChannel.StreamHandler(){

        @Override

        public void onListen(Object arguments, EventChannel.EventSink events) {

            eventSink = events;

        }


        @Override

        public void onCancel(Object arguments) {

            eventSink = null;

        }

    };

    // 事件派发流
    private  EventChannel.StreamHandler publishFailHandler = new  EventChannel.StreamHandler(){

        @Override

        public void onListen(Object arguments, EventChannel.EventSink events) {

            publishFailEventSink = events;

        }


        @Override

        public void onCancel(Object arguments) {

            publishFailEventSink = null;

        }

    };



    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "rabbit_mq");
        channel.setMethodCallHandler(this);

        // 声明将有数据返回
        final EventChannel eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "rabbit_mq/event");
        eventChannel.setStreamHandler(receiveHandler);

        EventChannel publishEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "rabbit_mq/publishEvent");

        publishEventChannel.setStreamHandler(streamHandler);

        EventChannel publishFailEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "rabbit_mq/publishFailEvent");

        publishFailEventChannel.setStreamHandler(publishFailHandler);


    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "connect":
                String host = call.argument("host");
                String userName = call.argument("userName");
                String password = call.argument("password");
                int heartbeat = call.argument("heartbeat");
                connect(host, userName, password,heartbeat, result);

                break;
            case "listenQueue":

                listenQueue(call.argument("queueName"), result);


                break;
            case "publish":
                String exchange = call.argument("exchange");
                String routingKey = call.argument("routingKey");
                String message = call.argument("message");
                publish(exchange, routingKey, message, result);
                break;
            case "createQueue":

                createQueue(call.argument("exchange"), call.argument("routingKey"), call.argument("queue"), result, call.argument("exchangeDurable"), call.argument("queueDurable"));

                break;
            default:
                result.notImplemented();
        }

    }

    void publish(String exchange, String routingKey, String messageString, Result result) {

        try{
            Runnable runnable = () -> {

                try {
                    if (mqChannel != null && mqChannel.isOpen()) {

                        mqChannel.basicPublish(exchange, routingKey, new AMQP.BasicProperties.Builder().deliveryMode(2).contentType("application/json").contentEncoding("UTF-8").build(),
                                messageString.getBytes());
                        if (mqChannel.waitForConfirms(60000L)) {
                            onPublishDataReceived(messageString);
                        }else{
                            onPublishDataFailReceived(messageString);
                        }
                    }else {
                        onPublishDataFailReceived(messageString);
                    }


                } catch (Exception e) {
                    onPublishDataFailReceived(messageString);
                }

            };
            executorService.execute(runnable);
        }catch (Exception ex){
            onPublishDataFailReceived(messageString);
        }

    }

    //定义队列
    void createQueue(String exchange, String routingKey, String queue, Result result, Boolean exchangeDurable,Boolean queueDurable) {

        Runnable runnable = () -> {

            //交换机声明，交换机类型为直连，第三个参数需要设置为可持久化
            try {
                if (mqChannel != null && mqChannel.isOpen()) {
                    mqChannel.exchangeDeclare(exchange, BuiltinExchangeType.DIRECT, exchangeDurable);
                    mqChannel.queueDeclare(queue, queueDurable, false, false, null);
                    //队列绑定路由
                    mqChannel.queueBind(queue, exchange, routingKey);
                    result.success("createQueueSuccess");
                }

            } catch (Exception e) {
                e.printStackTrace();
            }

        };
        executorService.execute(runnable);


    }


    //连接rabbiMQ
    void connect(String host, String userName, String password,int heartbeat, Result result) {
        Runnable runnable = () -> {

            try {
                if (mqChannel != null) {
                    result.success(true);
                    return;
                }
                ConnectionFactory factory = new ConnectionFactory();
                factory.setHost(host);
                factory.setPort(5672);
                factory.setRequestedHeartbeat(heartbeat);
                factory.setUsername(userName);
                factory.setPassword(password);
                factory.setConnectionTimeout(10 * 1000);
                factory.setHandshakeTimeout(10 * 1000);
                factory.setNetworkRecoveryInterval(10);
                // 开启Connection自动恢复。
                factory.setAutomaticRecoveryEnabled(true);
                // 开启Topology自动恢复。
                factory.setTopologyRecoveryEnabled(true);
                connection = factory.newConnection();

                mqChannel = connection.createChannel();
                //发送确认
                mqChannel.confirmSelect();
                result.success(true);

            } catch (Exception e) {
                connect(host, userName, password, heartbeat, result);
                e.printStackTrace();
            }
        };
        executorService.execute(runnable);
    }

    void listenQueue(String queueName, Result result) {
        //第二次监听时直接返回
        if( consumerList.indexOf(queueName)>=0){
            return;
        }else {
            consumerList.add(queueName);
        }

        Runnable runnable = () -> {

            try {

                if (mqChannel != null && mqChannel.isOpen()) {
                    //声明队列
                    mqChannel.queueDeclare(queueName, true, false, false, null);
                    //定义消费者
                    Consumer consumer = new DefaultConsumer(mqChannel) {
                        @Override
                        public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

                            String message = new String(body, "UTF-8");
                            onDataReceived(message);
                            mqChannel.basicAck(envelope.getDeliveryTag(),false);
                        }
                    };

                    mqChannel.basicConsume(queueName, false, consumer);
                    result.success("listenQueueSuccess");
                }

            } catch (IOException e) {
                e.printStackTrace();
            }
        };
        executorService.execute(runnable);
    }


    /**
     * 数据发送
     *
     * @param msgRecord
     */
    private void onDataReceived(final String msgRecord) {
        if (receiveEventSink != null) {

            mHandler.post(() -> {

                // 通过数据流发送数据
                receiveEventSink.success(msgRecord);
            });
        }
    }

    /**
     * 数据发送
     *
     * @param msgRecord
     */
    private void onPublishDataReceived(final String msgRecord) {
        if (eventSink != null) {


            mHandler.post(() -> {

                // 通过数据流发送数据
                eventSink.success(msgRecord);
            });


        }
    }

    /**
     * 数据发送
     *
     * @param msgRecord
     */
    private void onPublishDataFailReceived(final String msgRecord) {
        if (publishFailEventSink != null) {
            mHandler.post(() -> {
                // 通过数据流发送数据
                publishFailEventSink.success(msgRecord);
            });
        }
    }


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

}
