### 1. How to manage Flutter page lifecycle under FlutterBoost? Native Flutter's AppLifecycleState events may be inconsistent, for example ViewAppear will cause app state suspending or paused. How does hybrid stack handle this?
Answer: Under hybrid stack, page events are based on the following custom events:
```dart
enum ContainerLifeCycle {
  Init,
  Appear,
  WillDisappear,
  Disappear,
  Destroy,
  Background,
  Foreground
}
```
For page event duplication, please refer to the FAQ below.
### 2. How to determine if a flutter widget or container is currently visible?
Answer: There's an API to determine if the current page is visible:
```dart
bool isTopContainer = FlutterBoost.BoostContainer.of(context).onstage
```
Pass in your widget's context to determine if your widget is visible.
Based on this API, you can determine if your widget is visible, thereby avoiding receiving some duplicate lifecycle messages. Refer to this issue: https://github.com/alibaba/flutter_boost/issues/498

### 3. Hello, I'd like to ask about flutter_boost: ABC are all flutter pages, from A page -> B page -> C page, when opening C page I want to automatically close B page, when returning from C page directly return to A page, any method?
Answer: You just need to manipulate the vc array in Native layer's UINavigationController. Just like how you normally operate regular UIViewController. Because FlutterBoost's lifecycle management of Native layer's FlutterViewController and Dart layer's flutter page is consistent, when FlutterViewController is destroyed, its managed flutter page in dart layer will also be automatically destroyed.

### 4. In iOS, when voice over is on, the demo crashes on click interaction;
Answer: There's currently a bug in Flutter Engine in accessibility mode, we've already submitted an issue and PR to flutter. Please refer to this issue: https://github.com/alibaba/flutter_boost/issues/488 and its analysis. PR submitted to flutter is here: https://github.com/flutter/engine/pull/14155

### 5. Running the latest flutter boost on iOS simulator will crash
Answer: As mentioned in item 4 above, the latest flutter engine has a bug under voice over, which will cause crash. Because under simulator flutter will enable voice over mode by default, so it's actually assistive mode, which will trigger the above bug: "In iOS when voice over is on, demo crashes on click interaction".
Refer to Engine's code comment:
```c++
#if TARGET_OS_SIMULATOR
  // There doesn't appear to be any way to determine whether the accessibility
  // inspector is enabled on the simulator. We conservatively always turn on the
  // accessibility bridge in the simulator, but never assistive technology.
  platformView->SetSemanticsEnabled(true);
  platformView->SetAccessibilityFeatures(flags);
```

### 6. It seems official has already provided hybrid stack functionality, refer here: https://flutter.dev/docs/development/add-to-app; Is FlutterBoost still necessary?
Answer: The official solution only decouples FlutterViewController and FlutterEngine on the native side, so one FlutterEngine can switch different FlutterViewController or Activity for rendering. But it doesn't solve the problem of Native and Flutter page mixing, cannot guarantee lifecycle consistency on both sides. Even Flutter official suggests using FlutterBoost for this problem.
The main differences are:

|*|FlutterBoost2.0	|Flutter Official Solution	|Other Frameworks|
|----|----|----|----|
|Support arbitrary navigation between hybrid pages	|Y	|N	|Y|
|Consistent page lifecycle management (multi Flutter pages)	|Y	|N	|?|
|Support data passing between pages (return etc.)	|Y	|N	|N|
|Support swipe gesture	|Y	|Y	|Y|
|Support hero animation across pages	|Y	|Y	|N|
|Controllable memory and resource usage	|Y	|Y	|Y|
|Provide consistent page route solution	|Y	|Y	|N|
|iOS and Android capabilities and interfaces consistent	|Y	|N	|N|
|Framework stable, support Flutter1.9	|Y	|N	|?|
|Already support View level mixing	|N	|N	|N|

FlutterBoost also provides a command to create hybrid project at once: flutterboot. Code reference: https://github.com/alibaba-flutter/flutter-boot

### 7. If I need to pop a new FlutterViewController with a smaller frame through FlutterViewController, how should I implement it?
Answer: Without handling, you'll encounter window size change issues, but it can be solved. Refer to this issue: https://github.com/alibaba/flutter_boost/issues/435

### 8. How to set landscape orientation for Flutter ViewController
VC landscape orientation depends on NavigationController or rootVC. Can be set through the following methods:
1. Dart layer's SystemChrome.setPreferredOrientations function doesn't directly set orientation, but sets the page's preferred orientation
2. App's orientation control, besides info.plist settings, is mainly controlled by UIWindow.rootViewController. The process is roughly: hardware detects orientation change, calls UIWindow's orientation function, then calls its rootViewController's shouldAutorotate to determine if auto-rotate is needed, then takes the intersection of supportedInterfaceOrientations and info.plist settings to determine if can rotate
3. For orientation in UIViewController, it only works in rootviewcontroller

Example implementation steps:
1. Override NavigationController:
```objc
-(BOOL)shouldAutorotate
{
//    id currentViewController = self.topViewController;
//
//
//     if ([currentViewController isKindOfClass:[FlutterViewController class]])
//        return [currentViewController shouldAutorotate];

    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    id currentViewController = self.topViewController;
    if ([currentViewController isKindOfClass:[FlutterViewController class]]){
        NSLog(@"[XDEBUG]----fvc supported:%ld\n",[currentViewController supportedInterfaceOrientations]);
         return [currentViewController supportedInterfaceOrientations];
    }
    return UIInterfaceOrientationMaskAll;
}
```
2. Modify dart layer: Because SystemChrome.setPreferredOrientations setting is global, but hybrid stack is multi-page, so setting in main function will be overwritten when creating a new FlutterViewController later. To solve this problem, you need to add this statement in each dart page's build to set which orientation types each page can support

### 9. FlutterBoost for flutter1.12 crashes related to surface. Refer to this issue: https://github.com/flutter/flutter/issues/52455
May be caused by flutter engine bug

### 10. Some key conventions and FAQ for FlutterBoost ohos integration (If you still have questions, please carefully read the example code)
1. The second parameter of FlutterBoostEntry's constructor is a routerOptions, boost internally does not enforce its type (any), and allows business to customize routerOptions implementation, but needs to satisfy some conventions:
```
Non-Tab scenario: Must ensure the existence of uri: string, params: Record<string, Object>, uniqueId: string | null, these three properties, and not allowed to modify the names of these three properties
Tab scenario: Must ensure the existence of uri: string, params: Record<string, Object>, these two properties, and not allowed to modify the names of these two properties, not allowed to pass uniqueId here
```
2. How to solve when log output shows 'Missing uri' or 'Missing params'?
Answer: Follow the conventions in item 1 and correctly pass routerOptions.
3. If you need to use boost's capability to implement page return parameter passing, you need to use NavPathStack's pushPath method's onPop parameter. For data that needs to return to flutter page, please make sure to cast popInfo.result's type to Record<string, Object>. See example for details.
4. The fourth parameter of FlutterBoostEntry's constructor is an onPop callback function, which allows callers to control each page's exit logic at the page level. For taking over this callback function, the following conventions need to be satisfied:
```
Tab scenario: If you don't want the entire application to exit when a tab calls pop on dart side, you must take over this callback function, and don't make pop calls to the route in the takeover logic
Non-Tab scenario: You don't have to take over this callback function, but if you choose to take over, you must make pop calls to the route in the takeover logic
```
