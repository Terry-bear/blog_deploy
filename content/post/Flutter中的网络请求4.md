---
title: "Flutter中的网络请求4"
date: 2019-08-14T16:15:13+08:00
lastmod: 2019-08-14T16:15:13+08:00
draft: false
keywords: ["flutter"]
description: ""
tags: ["flutter"]
categories: ["code"]
author: "Terryzh"

postMetaInFooter: false

---

<!--more-->

# 基于shared_preferences本地存储操作

数据存储是开发APP必不可少的一部分，比如页面缓存，从网络上获取数据的本地持久化等，那么在Flutter中如何进行数据存储呢？

> Flutter官方推荐我们用sharedpreferences进行数据存储，类似于RN中的`AsyncStorage`。

![](https://img-blog.csdnimg.cn/20190529010007229.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25pY29sZWxpbGkx,size_16,color_FFFFFF,t_70)

## 什么是shared_preferences?

[shared_preferences](https://pub.dartlang.org/packages/shared_preferences#-installing-tab-)是Flutter社区开发的一个本地数据存取插件：

- 简单的，异步的，持久化的key-value存储系统；
- 在Android上它是基于`SharedPreferences`的；
- 在iOS上它是基于`NSUserDefaults`的；

## 如何使用shared_preferences？

首先在`pubspec.yaml`文件中添加：

```yml
dependencies:
  shared_preferences: ^0.5.1+
```

记得运行安装哦：`flutter packages get`

在需要用到的文件中导入：

```dart
import 'package:shared_preferences/shared_preferences.dart';
```

> 存储数据

```dart
final prefs = await SharedPreferences.getInstance();

// set value
prefs.setInt('counter', counter);
```

> 读取数据

```dart
final prefs = await SharedPreferences.getInstance();

// Try reading data from the counter key. If it does not exist, return 0.
final counter = prefs.getInt('counter') ?? 0;}
```

> 删除数据

```dart
final prefs = await SharedPreferences.getInstance();
prefs.remove('counter');
```

## shared_preferences有那些常用的API？

### 

![shared_preferences](https://img-blog.csdnimg.cn/20190529011028316.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25pY29sZWxpbGkx,size_16,color_FFFFFF,t_70)

### 

![shared_preferences](https://img-blog.csdnimg.cn/20190529011142923.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L25pY29sZWxpbGkx,size_16,color_FFFFFF,t_70)



## 基于shared_preferences实现计数器Demo

![图片描述](https://img.mukewang.com/szimg/5d42cff60a760b7603380284.jpg)

> 示例源码：

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: Text('shared_preferences'),
      ),
      body: _CounterWidget(),
    ),
  ));
}

class _CounterWidget extends StatefulWidget {
  @override
  _CounterState createState() => _CounterState();
}

class _CounterState extends State<_CounterWidget> {
  String countString = '';
  String localCount = '';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          RaisedButton(
              onPressed: _incrementCounter, child: Text('Increment Counter')),
          RaisedButton(onPressed: _getCounter, child: Text('Get Counter')),
          Text(
            countString,
            style: TextStyle(fontSize: 20),
          ),
          Text(
            'result：' + localCount,
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  _incrementCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      countString = countString + " 1";
    });
    int counter = (prefs.getInt('counter') ?? 0) + 1;
    await prefs.setInt('counter', counter);
  }

  _getCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      localCount = prefs.getInt('counter').toString();
    });
  }
}
```

## 参考

- [Storing key-value data on disk](https://flutter.dev/docs/cookbook/persistence/key-value)

> > 转自imooc[CrazyCodeBoy](https://coding.imooc.com/learn/questiondetail/134650.html)

