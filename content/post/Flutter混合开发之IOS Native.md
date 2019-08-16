---
title: "Flutter混合开发之IOS Native"
date: 2019-08-16T14:44:10+08:00
lastmod: 2019-08-16T14:44:10+08:00
draft: false
keywords: ["flutter"]
description: ""
tags: ["flutter"]
categories: ["code"]
author: "Terryzh"

postMetaInFooter: false

---

<!--more-->

在Flutter的应用场景中，有时候一个APP只有部分页面是由Flutter实现的，比如：我们常用的闲鱼App，它宝贝详情页面是由Flutter实现的，这种开发模式被称为混合开发。

**混合开发的一些其他应用场景：**

> 在原有项目中加入Flutter页面，在Flutter项目中加入原生页面。

![](http://www.devio.org/io/flutter_app/img/Flutter_hybrid.png)



> 原生页面中嵌入Flutter模块

![](http://www.devio.org/io/flutter_app/img/Flutter_hybrid_item.png)

> Flutter页面中嵌入原生模块

![](http://www.devio.org/io/flutter_app/img/Flutter_hybrid_map.png)

以上这些都属于Flutter混合开发的范畴，那么如何进行Flutter混合开发呢？

在这篇文章中我将向大家介绍Flutter混合开发的流程，需要掌握的技术，以及一些经验技巧，

## 创建Flutter module

在做混合开发之前我们首先需要创建一个`Flutter module`。

假如你的Native项目是这样的：`xxx/flutter_hybrid/FlutterHybridiOS`:

```bash
$ cd xxx/flutter_hybrid/
$ flutter create -t module flutter_module
```

上面代码会切换到你的IOS项目的上一级目录，并创建一个flutter模块：

```
//flutter_module/
.android
.gitignore
.idea
.ios
.metadata
.packages
build
flutter_module_android.iml
flutter_module.iml
lib
pubspec.lock
pubspec.yaml
README.md
test
```

上面是`flutter_module`中的文件结构，你会发现他们里面包含`.android`与`.ios`, 这两个文件夹是隐藏文件，也是这个`flutter_module`宿主工程：

* `.android`-`flutter_module`的Android宿主工程；
* `.ios`-`flutter_module`的iOS宿主工程；
* `lib`-`flutter_module`的Dart部分的代码；
* `pubspec.yaml`-`flutter_module`的项目依赖配置文件；

> 因为宿主工程的存在，我们这个`flutter_module`在不加额外的配置的情况下是可以独立运行的，通过安装了Flutter与Dart插件的AndroidStudio打开这个`flutter_module`项目，通过运行按钮是可以直接运行它的。

## 为已存在的iOS应用添加Flutter module依赖

接下来我们需要配置我们iOS项目的Flutter module依赖，接下来的配置需要用到CocoaPods，如果你还没有用到CocoaPods，可以参考[https://cocoapods.org/](https://cocoapods.org/)上面的说明来安装CocoaPods。

#### 在`podfile`文件中添加`flutter`依赖

如果你的iOS项目中没有`Podfile`文件可以通过：

```bash
pod init
```

初始化一个，接下来添加

```bash
 flutter_application_path = 'path/to/my_flutter/'
  eval(File.read(File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')), binding)
```

例如：

```bash
target 'FlutterHybridiOS' do
	flutter_application_path = '../flutter_module/'
	eval(File.read(File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')), binding)
	
	target 'FlutterHybridiOSTests' do
		inherit!: search_paths
	end
	
	target 'FlutterHybridiOSUITests' do
		inherit!: search_paths
	end
end
```



#### 安装依赖

在iOS项目的根目录运行：

```bash
pod install
```

你会看到：

```bash
pod install
Analyzing dependencies
Fetching podspec for `Flutter` from `../flutter_module/.ios/Flutter/engine`
Fetching podspec for `FlutterPluginRegistrant` from `../flutter_module/.ios/Flutter/FlutterPluginRegistrant`
Downloading dependencies
Installing Flutter (1.0.0)
Installing FlutterPluginRegistrant (0.0.1)
Generating Pods project
Integrating client project
[!] Please close any current Xcode sessions and use `FlutterHybridiOS.xcworkspace` for  this project from now on.
Sending stats
Pod installation complete！ There are 2 dependencies from the Podfile and 2 total pods installed.
[!]  Automatically assigning platform `ios` with version `12.1` on target `FlutterHybridiOS`  because no platform was specified. Please specify a platform for this target in  your Podfile. See `https://guides.cocoapods.org/syntax/podfile.html#platform`.
```

当你在`flutter_module/pubspec.yaml`添加一个Flutter插件时，需要在`flutter_module`目录下运行：

```bash
flutter packages get
```

来刷新`podhelper.rb`脚本中插件列表，然后在iOS目录下运行：

```bash
pod install
```

这样以来`podhelper.rb`脚本才能确保你的插件和`Flutter.framework`能够添加到你的iOS项目中。



#### 禁止Bitcode

目前Flutter还不支持Bitcode，所以集成了Flutter的iOS项目需要禁用Bitcode：

用XCode打开你的项目如：`xxx.xcworkspace`

然后在：

```bash
Build Settings->Build Options->Enable Bitcode 
```

中禁用Bitcode:

![](http://www.devio.org/io/flutter_app/img/blog/Disable_Bitcode.png)

添加 build phase以构建Dart代码

![](http://www.devio.org/io/flutter_app/img/blog/Add_build_phase.png)

根据上图的提示创建一个`build phase`，然后展开`Run Script`并添加下面配置：

```bash
"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" build
"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" embed
```

![](http://www.devio.org/io/flutter_app/img/blog/shell_field.png)

最后记得根据上图的提示，将`Run Script`到紧挨着`Target Dependencies phase`的下面，接下来就可以通过

`⌘B`构建你的项目了。

### 在Object-c中调用Flutter module

至此，我们已经为我们的iOS项目添加了Flutter所必须的依赖，接下来我们来看如何在Object-c中调用Flutter模块：

在Object-c中调用Flutter模块有两种方式：

* 直接使用`FlutterViewController`的方式；
* 使用`FlutterEngine`的方式；

#### 直接使用flutterviewcontroller的方式

```
// ⁨flutter_hybrid⁩ ▸ ⁨FlutterHybridiOS⁩ ▸ ⁨FlutterHybridiOS⁩ ▸ ViewController.m 

#import 
#import "AppDelegate.h"
#import "ViewController.h"
#import  // 如果你需要用到Flutter插件时

FlutterViewController *flutterViewController = [FlutterViewController new];
GeneratedPluginRegistrant.register(with: flutterViewController);//如果你需要用到Flutter插件时
[flutterViewController setInitialRoute:@"route1"];
    
[self presentViewController:flutterViewController animated:true completion:nil];
```

通过这种方式我们可以使用`flutterViewController setInitialRoute`的方法为传递了字符串“route1”来告诉Dart代码在Flutter视图中显示哪个小部件。 Flutter模块项目的`lib/main.dart`文件需要通过`window.defaultRouteName`来获取Native指定要显示的路由名，以确定要创建哪个窗口小部件并传递给runApp：

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(_widgetForRouter(window.defaultRouterName));

Widget _widgetForRouter(String route) {
  switch (route) {
    case 'route1':
      return SomeWidget(...);
    case 'route2':
      return SomeOtherWidget(...);
    default:
      return Center(
      	child: Text('Unknown route: $route', textDirection: TextDirection.ltr),
      );
  }
}
```



#### 使用`FlutterEngine`的方式

> AppDelegate.h

```
#import 
#import 

@interface AppDelegate : FlutterAppDelegate
@property (nonatomic,strong) FlutterEngine *flutterEngine;
@end
```

> AppDelegate.m

```
#import  // 如果你需要用到Flutter插件时
#include "AppDelegate.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.flutterEngine = [[FlutterEngine alloc] initWithName:@"io.flutter" project:nil];
  [self.flutterEngine runWithEntrypoint:nil];
  [GeneratedPluginRegistrant registerWithRegistry:self.flutterEngine]; //如果你需要用到Flutter插件时
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
@end
```

> ViewController.m

```
// ⁨flutter_hybrid⁩ ▸ ⁨FlutterHybridiOS⁩ ▸ ⁨FlutterHybridiOS⁩ ▸ ViewController.m 

 FlutterEngine *flutterEngine = [(AppDelegate *)[[UIApplication sharedApplication] delegate] flutterEngine];
    FlutterViewController *flutterViewController = [[FlutterViewController alloc] initWithEngine:flutterEngine nibName:nil bundle:nil];
    [self presentViewController:flutterViewController animated:false completion:nil];
```

>因为我们在AppDelegate.m中提前初始化了`FlutterEngine`，所以这种方式打开一个Flutter模块的速度要比第一种方式要快一些。



#### 调用Flutter module时传递数据

在上文中，我们无论是通过直接使用`FlutterViewController`的方式还是通过`FlutterEngine`的方式，都允许我们在加载Flutter module时传递一个String类型的`initialRoute`参数，从参数名字它是用作路由名的，但是既然Flutter给我们开了这个口子，那我们是不是可以搞点事情啊，传递点我们想传的其他参数呢，比如：

```java
[flutterViewController setInitialRoute:@"{name:'devio',dataList:['aa','bb',''cc]}"]
```

然后在Flutter module通过如下方式获取：

```
import 'dart:ui';//要使用window对象必须引入

String initParams=window.defaultRouteName;
//序列化成Dart obj 敢你想干的
...
```



## 编写Dart代码

### 运行项目

接下来，我们就可以运行它了，经过上述步骤，我们就可以以运行普通iOS项目的方式来通过XCode运行一个集成了Flutter的iOS项目了。

![](http://www.devio.org/io/flutter_app/img/blog/Flutter_hybrid_ios.png)

### 热重启/重新加载

![](http://www.devio.org/io/flutter_app/img/blog/hot_reload_ios.gif)

大家知道我们在做Flutter开发的时候，它带有热重启/重新加载的功能，但是你可能会发现，混合开发中在iOS项目中集成了Flutter项目，Flutter的热重启/重新加载功能好像失效了，那怎么启用混合开发汇总Flutter的热重启/重新加载呢：

* 打开一个模拟器，或连接一个设备到电脑上；
* 关闭我们的APP，然后运行`flutter attach`

```
$ cd flutter_hybrid/flutter_module
$ flutter attach
Checking for advertised Dart observatories...
Waiting for a connection from Flutter on iPhone X...
```

> 注意：如果你同时有多个模拟器或连接的设备，运行`flutter attach`会提示你选择一个设备：

```bash
Android SDK built for x86 • emulator-5554                        • android-x86 • Android 8.1.0 (API 27) (emulator)
iPhone X                  • 3E3FA943-715F-482F-B003-D46F5902C56C • ios         • iOS 12.1 (simulator)
```

接下来我们需要`flutter attach -d`来指定一个设备：

```bash
flutter attach -d 'emulator-5554'
```

注意`-d`后面跟的设备ID。

* 运行App，然后你会看到：

```
$ flutter attach
More than one device connected; please specify a device with the '-d ' flag, or use '-d all' to act on all devices.

Android SDK built for x86 • emulator-5554                        • android-x86 • Android 8.1.0 (API 27) (emulator)
iPhone X                  • 3E3FA943-715F-482F-B003-D46F5902C56C • ios         • iOS 12.1 (simulator)
jphdeMacBook-Pro:flutter_module jph$ flutter attach -d '3E3FA943-715F-482F-B003-D46F5902C56C'
Checking for advertised Dart observatories...
Waiting for a connection from Flutter on iPhone X...
Done.
Syncing files to device iPhone X...                              1,613ms

?  To hot reload changes while running, press "r". To hot restart (and rebuild state), press "R".
An Observatory debugger and profiler on iPhone X is available at: http://127.0.0.1:64108/
For a more detailed help message, press "h". To detach, press "d"; to quit, press "q".
```

说明l连接成功了，接下来就可以通过上面的提示来进行热加载/热重启了，在终端输入：

* r: 热加载；
* R: 热重启;
* h: 获取帮助；
* d：断开连接；

### 调试Dart代码

混合开发的模式下，如何更好更高效的调试我们的代码呢，接下来我就跟大家分享一种混合开发模式下高效调试代码的方式：

* 关闭APP（这步很关键）
* 点击AndroidStudio的`Flutter Attach`按钮(需要首先安装Flutter与Dart插件)
* 启动APP

![](http://www.devio.org/io/flutter_app/img/blog/Flutter_hybrid_attach.png)

接下来就可以像调试普通Flutter项目一样来调试混合开发的模式下的Dart代码了。

> 除了以上步骤不同之外，接下来的调试和我们之前课程中的Flutter调试技巧都是通用的，需要的同学可以学习下我们前面的课程；

还有一点需要注意：

>  大家在运行iOS工程时一定要用XCode运行，因为Flutter模式下的AndroidStudio运行的是Flutter module下的`.iOS`中的工程。

### 发布应用

发布iOS应用我们需要有一个99美元的账号用于将App上传到AppStore，或者是299美元的企业级账号用于将App发布到自己公司的服务器或第三方公司的服务器。

接下来我们就需要进行申请APPID ➜ 在Tunes Connect创建应用 ➜ 打包程序 ➜ 将应用提交到app store等几大步骤。

[官方文档](https://developer.apple.com/library/content/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/About.html#//apple_ref/doc/uid/TP40011225-CH1-SW1)

