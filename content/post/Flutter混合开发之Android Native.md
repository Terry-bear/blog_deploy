---
title: "Flutter混合开发之Android Native"
date: 2019-08-16T14:31:45+08:00
lastmod: 2019-08-16T14:31:45+08:00
draft: false
keywords: ["flutter"]
description: “Flutter与Android Native通信"
tags: ["flutter"]
categories: ["code"]
author: "Terryzh"

postMetaInFooter: false

---

<!--more-->

在做Flutter开发的时候通常离不了Flutter和Native之间的通信，比如：初始化Flutter时Native向Dart传递数据，Dart调用Native的相册选择图片，Dart调用Native的模块进行一些复杂的计算，Native将一些数据(GPS信息，陀螺仪，传感器等)主动传递给Dart等。

在Flutter中Dart和Native之间通信的几种方式以及其原理和使用技巧；

接下来我将分场景来介绍Dart 和Native之间的通信。

> 几种通信场景：

- 初始化Flutter时Native向Dart传递数据；
- Native发送数据给Dart；
- Dart发送数据给Native；
- Dart发送数据给Native，然后Native回传数据给Dart；

![Flutter-Dart-Native-Communication](http://www.devio.org/io/flutter_app/img/blog/Flutter-Dart-Native-Communication.png)

## Flutter 与 Native通信机制

在讲解Flutter 与 Native之间是如何传递数据之前，我们先来了解下 Flutter与Native的通信机制，Flutter和Native的通信是通过Channel来完成的。

消息使用Channel（平台通道）在客户端（UI）和主机（平台）之间传递，如下图所示：

![PlatformChannels](http://www.devio.org/io/flutter_app/img/blog/PlatformChannels.png)

> Flutter中消息的传递是完全异步的；

Channel所支持的数据类型对照表：

| Dart                       | Android             | iOS                                            |
| :------------------------- | :------------------ | :--------------------------------------------- |
| null                       | null                | nil (NSNull when nested)                       |
| bool                       | java.lang.Boolean   | NSNumber numberWithBool:                       |
| int                        | java.lang.Integer   | NSNumber numberWithInt:                        |
| int, if 32 bits not enough | java.lang.Long      | NSNumber numberWithLong:                       |
| double                     | java.lang.Double    | NSNumber numberWithDouble:                     |
| String                     | java.lang.String    | NSString                                       |
| Uint8List                  | byte[]              | FlutterStandardTypedData typedDataWithBytes:   |
| Int32List                  | int[]               | FlutterStandardTypedData typedDataWithInt32:   |
| Int64List                  | long[]              | FlutterStandardTypedData typedDataWithInt64:   |
| Float64List                | double[]            | FlutterStandardTypedData typedDataWithFloat64: |
| List                       | java.util.ArrayList | NSArray                                        |
| Map                        | java.util.HashMap   | NSDictionary                                   |

Flutter定义了三种不同类型的Channel：

- BasicMessageChannel：用于传递字符串和半结构化的信息，持续通信，收到消息后可以回复此次消息，如：Native将遍历到的文件信息陆续传递到Dart，在比如：Flutter将从服务端陆陆续获取到信息交个Native加工，Native处理完返回等；
- MethodChannel：用于传递方法调用（method invocation）一次性通信：如Flutter调用Native拍照；
- EventChannel: 用于数据流（event streams）的通信，持续通信，收到消息后无法回复此次消息，通过长用于Native向Dart的通信，如：手机电量变化，网络连接变化，陀螺仪，传感器等；

这三种类型的类型的Channel都是全双工通信，即A <=> B，Dart可以主动发送消息给platform端，并且platform接收到消息后可以做出回应，同样，platform端可以主动发送消息给Dart端，dart端接收数后返回给platform端。

### BasicMessageChannel用法

#### Native端：

> 构造方法原型

```java
BasicMessageChannel(BinaryMessenger messenger, String name, MessageCodec<T> codec)
```

- `BinaryMessenger messenger` - 消息信使，是消息的发送与接收的工具；

- `String name` - Channel的名字，也是其唯一标识符；

- ```java
  MessageCodec<T> codec
  ```

   

  \- 消息的编解码器，它有几种不同类型的实现：

  - `BinaryCodec` - 最为简单的一种Codec，因为其返回值类型和入参的类型相同，均为二进制格式（Android中为ByteBuffer，iOS中为NSData）。实际上，BinaryCodec在编解码过程中什么都没做，只是原封不动将二进制数据消息返回而已。或许你会因此觉得BinaryCodec没有意义，但是在某些情况下它非常有用，比如使用BinaryCodec可以使传递内存数据块时在编解码阶段免于内存拷贝；
  - `StringCodec` - 用于字符串与二进制数据之间的编解码，其编码格式为UTF-8；
  - `JSONMessageCodec` - 用于基础数据与二进制数据之间的编解码，其支持基础数据类型以及列表、字典。其在iOS端使用了NSJSONSerialization作为序列化的工具，而在Android端则使用了其自定义的JSONUtil与StringCodec作为序列化工具；
  - `StandardMessageCodec` - 是BasicMessageChannel的默认编解码器，其支持基础数据类型、二进制数据、列表、字典，其工作原理；

> setMessageHandler方法原型

```java
void setMessageHandler(BasicMessageChannel.MessageHandler<T> handler)
```

- `BasicMessageChannel.MessageHandler<T> handler` - 消息处理器，配合`BinaryMessenger`完成消息的处理；

在创建好`BasicMessageChannel`后，如果要让其接收Dart发来的消息，则需要调用它的`setMessageHandler`方法为其设置一个消息处理器。

> BasicMessageChannel.MessageHandler原型

```java
public interface MessageHandler<T> {
    void onMessage(T var1, BasicMessageChannel.Reply<T> var2);
}
```

- `onMessage(T var1, BasicMessageChannel.Reply<T> var2)` - 用于接受消息，var1是消息内容，var2是回复此消息的回调函数；

> send方法原型

```java
void send(T message)
void send(T message, BasicMessageChannel.Reply<T> callback)
```

- `T message` - 要传递给Dart的具体信息；
- `BasicMessageChannel.Reply<T> callback` - 消息发出去后，收到Dart的回复的回调函数；

在创建好`BasicMessageChannel`后，如果要向Dart发送消息，可以调用它的`send`方法向Dart传递数据。

```java
public class BasicMessageChannelPlugin implements BasicMessageChannel.MessageHandler<String>, BasicMessageChannel.Reply<String> {
    private final Activity activity;
    private final BasicMessageChannel<String> messageChannel;

    static BasicMessageChannelPlugin registerWith(FlutterView flutterView) {
        return new BasicMessageChannelPlugin(flutterView);
    }

    private BasicMessageChannelPlugin(FlutterView flutterView) {
        this.activity = (Activity) flutterView.getContext();
        this.messageChannel = new BasicMessageChannel<>(flutterView, "BasicMessageChannelPlugin", StringCodec.INSTANCE);
        //设置消息处理器，处理来自Dart的消息
        messageChannel.setMessageHandler(this);
    }

    @Override
    public void onMessage(String s, BasicMessageChannel.Reply<String> reply) {//处理Dart发来的消息
        reply.reply("BasicMessageChannel收到：" + s);//可以通过reply进行回复
        if (activity instanceof IShowMessage) {
            ((IShowMessage) activity).onShowMessage(s);
        }
        Toast.makeText(activity, s, Toast.LENGTH_SHORT).show();
    }

    /**
     * 向Dart发送消息，并接受Dart的反馈
     *
     * @param message  要给Dart发送的消息内容
     * @param callback 来自Dart的反馈
     */
    void send(String message, BasicMessageChannel.Reply<String> callback) {
        messageChannel.send(message, callback);
    }

    @Override
    public void reply(String s) {

    }
}
```

[实例源码下载](https://git.imooc.com/coding-321/flutter_trip/src/master/demo/flutter_hybrid)

#### Dart端：

> 构造方法原型

```dart
const BasicMessageChannel(this.name, this.codec);
```

- `String name` - Channel的名字，要和Native端保持一致；
- `MessageCodec<T> codec` - 消息的编解码器，要和Native端保持一致，有四种类型的实现具体可以参考Native端的介绍；

> setMessageHandler方法原型

```dart
void setMessageHandler(Future<T> handler(T message));
```

- `Future<T> handler(T message)` - 消息处理器，配合`BinaryMessenger`完成消息的处理；

在创建好`BasicMessageChannel`后，如果要让其接收Native发来的消息，则需要调用它的`setMessageHandler`方法为其设置一个消息处理器。

> send方法原型

```dart
 Future<T> send(T message);
```

- `T message` - 要传递给Native的具体信息；
- `Future<T>` - 消息发出去后，收到Native回复的回调函数；

在创建好`BasicMessageChannel`后，如果要向Native发送消息，可以调用它的`send`方法向Native传递数据。

```dart
import 'package:flutter/services.dart';
...
static const BasicMessageChannel _basicMessageChannel =
      const BasicMessageChannel('BasicMessageChannelPlugin', StringCodec());
...
//使用BasicMessageChannel接受来自Native的消息，并向Native回复
_basicMessageChannel
    .setMessageHandler((String message) => Future<String>(() {
          setState(() {
            showMessage = message;
          });
          return "收到Native的消息：" + message;
        }));
//使用BasicMessageChannel向Native发送消息，并接受Native的回复
String response;
    try {
       response = await _basicMessageChannel.send(value);
    } on PlatformException catch (e) {
      print(e);
    }
...
```

[实例源码下载](https://git.imooc.com/coding-321/flutter_trip/src/master/demo/flutter_hybrid)

### MethodChannel用法

#### Native端：

> 构造方法原型

```java
//会构造一个StandardMethodCodec.INSTANCE类型的MethodCodec
MethodChannel(BinaryMessenger messenger, String name)
//或
MethodChannel(BinaryMessenger messenger, String name, MethodCodec codec)
```

- `BinaryMessenger messenger` - 消息信使，是消息的发送与接收的工具；
- `String name` - Channel的名字，也是其唯一标识符；
- `MethodCodec codec` - 用作`MethodChannel`的编解码器；

> setMethodCallHandler方法原型

```java
setMethodCallHandler(@Nullable MethodChannel.MethodCallHandler handler);
```

- `@Nullable MethodChannel.MethodCallHandler handler` - 消息处理器，配合BinaryMessenger完成消息的处理；

在创建好MethodChannel后，需要调用它的setMessageHandler方法为其设置一个消息处理器，以便能加收来自Dart的消息。

> MethodChannel.MethodCallHandler原型

```java
public interface MethodCallHandler {
    void onMethodCall(MethodCall var1, MethodChannel.Result var2);
}
```

- `onMethodCall(MethodCall call, MethodChannel.Result result)` - 用于接受消息，call是消息内容，它有两个成员变量String类型的`call.method`表示调用的方法名，Object 类型的`call.arguments`表示调用方法所传递的入参；`MethodChannel.Result result`是回复此消息的回调函数提供了`result.success`，`result.error`，`result.notImplemented`方法调用；

```java
public class MethodChannelPlugin implements MethodCallHandler {
    private final Activity activity;

    /**
     * Plugin registration.
     */
    public static void registerWith(FlutterView flutterView) {
        MethodChannel channel = new MethodChannel(flutterView, "MethodChannelPlugin");
        MethodChannelPlugin instance = new MethodChannelPlugin((Activity) flutterView.getContext());
        channel.setMethodCallHandler(instance);
    }

    private MethodChannelPlugin(Activity activity) {
        this.activity = activity;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {//处理来自Dart的方法调用
            case "showMessage":
                showMessage(call.arguments());
                result.success("MethodChannelPlugin收到：" + call.arguments);//返回结果给Dart
                break;
            default:
                result.notImplemented();
        }
    }

    /**
     * 展示来自Dart的数据
     *
     * @param arguments
     */
    private void showMessage(String arguments) {
        if (activity instanceof IShowMessage) {
            ((IShowMessage) activity).onShowMessage(arguments);
        }
        Toast.makeText(activity, arguments, Toast.LENGTH_SHORT).show();
    }
}
```

[实例源码下载](https://git.imooc.com/coding-321/flutter_trip/src/master/demo/flutter_hybrid)

#### Dart端：

> 构造方法原型

```dart
const MethodChannel(this.name, [this.codec = const StandardMethodCodec()])
```

- `String name` - Channel的名字，要和Native端保持一致；
- `MethodCodec codec` - 消息的编解码器，默认是StandardMethodCodec，要和Native端保持一致；

> invokeMethod方法原型

```dart
Future<T> invokeMethod<T>(String method, [ dynamic arguments ]);
```

- `String method`：要调用Native的方法名；
- `[ dynamic arguments ]`：调用Native方法传递的参数，可不传；

```dart
import 'package:flutter/services.dart';
...
static const MethodChannel _methodChannelPlugin =
      const MethodChannel('MethodChannelPlugin');
...
String response;
    try {
		response = await _methodChannelPlugin.invokeMethod('send', value);
    } on PlatformException catch (e) {
      print(e);
    }
...
```

### EventChannel用法

#### Native端：

> 构造方法原型

```java
//会构造一个StandardMethodCodec.INSTANCE类型的MethodCodec
EventChannel(BinaryMessenger messenger, String name)
//或
EventChannel(BinaryMessenger messenger, String name, MethodCodec codec)
```

- `BinaryMessenger messenger` - 消息信使，是消息的发送与接收的工具；
- `String name` - Channel的名字，也是其唯一标识符；
- `MethodCodec codec` - 用作`EventChannel`的编解码器；

> setStreamHandler方法原型

```java
void setStreamHandler(EventChannel.StreamHandler handler)
```

`EventChannel.StreamHandler handler` - 消息处理器，配合BinaryMessenger完成消息的处理；
在创建好EventChannel后，如果要让其接收Dart发来的消息，则需要调用它的`setStreamHandler`方法为其设置一个消息处理器。

> EventChannel.StreamHandler原型

```java
public interface StreamHandler {
    void onListen(Object args, EventChannel.EventSink eventSink);

    void onCancel(Object o);
}
```

- `void onListen(Object args, EventChannel.EventSink eventSink)` - Flutter Native监听事件时调用，`Object args`是传递的参数，`EventChannel.EventSink eventSink`是Native回调Dart时的会回调函数，`eventSink`提供`success`、`error`与`endOfStream`三个回调方法分别对应事件的不同状态；
- `void onCancel(Object o)` - Flutter取消监听时调用；

```java
public class EventChannelPlugin implements EventChannel.StreamHandler {
    private List<EventChannel.EventSink> eventSinks = new ArrayList<>();

    static EventChannelPlugin registerWith(FlutterView flutterView) {
        EventChannelPlugin plugin = new EventChannelPlugin();
        new EventChannel(flutterView, "EventChannelPlugin").setStreamHandler(plugin);
        return plugin;
    }

    void sendEvent(Object params) {
        for (EventChannel.EventSink eventSink : eventSinks) {
            eventSink.success(params);
        }
    }

    @Override
    public void onListen(Object args, EventChannel.EventSink eventSink) {
        eventSinks.add(eventSink);
    }

    @Override
    public void onCancel(Object o) {

    }
}
```

[实例源码下载](https://git.imooc.com/coding-321/flutter_trip/src/master/demo/flutter_hybrid)

> Dart端：

> 构造方法原型

```dart
const EventChannel(this.name, [this.codec = const StandardMethodCodec()]);
```

- `String name` - Channel的名字，要和Native端保持一致；
- `MethodCodec codec` - 消息的编解码器，默认是StandardMethodCodec，要和Native端保持一致；

> `receiveBroadcastStream`方法原型

```dart
Stream<dynamic> receiveBroadcastStream([ dynamic arguments ]);
```

- `dynamic arguments` - 监听事件时向Native传递的数据；

初始化一个广播流用于从channel中接收数据，它返回一个Stream接下来需要调用Stream的`listen`方法来完成注册，另外需要在页面销毁时调用Stream的`cancel`方法来取消监听；

```dart
import 'package:flutter/services.dart';
...
static const EventChannel _eventChannelPlugin =
      EventChannel('EventChannelPlugin');
StreamSubscription _streamSubscription;
  @override
  void initState() {
    _streamSubscription=_eventChannelPlugin
        .receiveBroadcastStream()
        .listen(_onToDart, onError: _onToDartError);
    super.initState();
  }
  @override
  void dispose() {
    if (_streamSubscription != null) {
      _streamSubscription.cancel();
      _streamSubscription = null;
    }
    super.dispose();
  }
  void _onToDart(message) {
    setState(() {
      showMessage = message;
    }); 
  }
  void _onToDartError(error) {
    print(error);
  }
...
```

[实例源码下载](https://git.imooc.com/coding-321/flutter_trip/src/master/demo/flutter_hybrid)

## 1. 初始化Flutter时Native向Dart传递数据

![init-data-to-js](http://www.devio.org/io/flutter_app/img/blog/init-data-to-dart.gif)

在Flutter的API中提供了Native在初始化Dart页面时传递数据给Dart的方式，这种传递数据的方式比下文中所讲的其他几种传递数据的方式发生的时机都早。

因为很少有资料介绍这种方式，所以可能有很多同学还不知道这种方式，不过不要紧，接下来我就向大家介绍如何使用这种方式来传递数据给Dart。

Android向Flutter传递初始化数据`initialRoute`

Flutter允许我们在初始化Flutter页面时向Flutter传递一个String类型的`initialRoute`参数，从参数名字它是用作路由名的，但是既然Flutter给我们开了这个口子，那我们是不是可以搞点事情啊，传递点我们想传的其他参数呢，比如：

```java
FragmentTransaction tx = getSupportFragmentManager().beginTransaction();
                tx.replace(R.id.someContainer, Flutter.createFragment("{name:'devio',dataList:['aa','bb',''cc]}"));
                tx.commit();
//or
View flutterView = Flutter.createView(
      MainActivity.this,
      getLifecycle(),
      "route1"
    );
FrameLayout.LayoutParams layout = new FrameLayout.LayoutParams(600, 800);
layout.leftMargin = 100;
layout.topMargin = 200;
addContentView(flutterView, layout);
```

然后在Flutter module通过如下方式获取：

```dart
import 'dart:ui';//要使用window对象必须引入

String initParams=window.defaultRouteName;
//序列化成Dart obj 敢你想干的
...
```

通过上述方案的讲解是不是给大家分享了一个新的思路呢。
接下来，我们先来看一下如何在`Android`上来传递这些初始化数据。

## 2. Native到Dart的通信(Native发送数据给Dart)

在Flutter 中Native向Dart传递消息可以通过`BasicMessageChannel`或`EventChannel`都可以实现：

### 通过`BasicMessageChannel`的方式

![BasicMessageChannel](http://www.devio.org/io/flutter_app/img/blog/native-to-dart-BasicMessageChannel.gif)

> 如何实现？

### 通过`EventChannel`的方式

![EventChannel](http://www.devio.org/io/flutter_app/img/blog/native-to-dart-EventChannel.gif)

> 如何实现？

以上就是使用不同Channel实现Native到Dart通信的原理及方式，接下来我们来看一下实现Dart到Native之间通信的原理及方式。

## 3. Dart到Native的通信(Dart发送数据给Native)

在Flutter 中Dart向Native传递消息可以通过`BasicMessageChannel`或`MethodChannel`都可以实现：

### 通过`BasicMessageChannel`的方式

![dart-to-native-BasicMessageChannel](http://www.devio.org/io/flutter_app/img/blog/dart-to-native-BasicMessageChannel.gif)

### 通过`MethodChannel`的方式

![dart-to-native-BasicMessageChannel](http://www.devio.org/io/flutter_app/img/blog/dart-to-native-MethodChannel.gif)

## 参考

- [实例源码下载](https://git.imooc.com/coding-321/flutter_trip/src/master/demo/flutter_hybrid)
- [Flutter 开发跨平台实战](http://coding.imooc.com/class/321.html)
- [React Native 开发跨平台实战](http://coding.imooc.com/class/304.html)
- [Writing custom platform-specific code](https://flutter.dev/docs/development/platform-integration/platform-channels)