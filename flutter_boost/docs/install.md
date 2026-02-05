# Platform Installation

## 1. Directory Structure

We create a new folder FlutterBoostExample, which contains three other folders. The three are your Android project, iOS project, and the flutter module to be integrated.
Note that flutter must be a module, not a project. The way to determine if it's a module is to check if it has android and ios folders. If it doesn't, then it's a module, which is correct.

Here we name them `BoostTestAndroid`, `BoostTestIOS`, and `flutter_module`
Note: These three projects should be in the same directory level.

Now we can start working

## Dart Section

1. First, you need to add `FlutterBoost` dependency to `yaml` file

```yaml
flutter_boost:
  git:
    url: 'https://github.com/alibaba/flutter_boost.git'
    ref: '4.6.5'
```

After that, run `flutter pub get` in the flutter project and dart side integration is complete. Then you can add some code on the dart side. The following code is based on example3.0

// Note: If your project already has a custom Binding that inherits from `WidgetsFlutterBinding`, you only need to add `BoostFlutterBinding` with it
// If your project doesn't have a custom Binding, you can refer to this `CustomFlutterBinding` approach
// `BoostFlutterBinding` is used to take over Flutter App's lifecycle, it must be integrated

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boost/flutter_boost.dart';

void main() {
  /// The CustomFlutterBinding call here is essential, used to control Boost state's resume and pause
  CustomFlutterBinding();
  runApp(MyApp());
}


/// Create a custom Binding, the inheritance and with relationship is as follows, nothing needs to be written inside
class CustomFlutterBinding extends WidgetsFlutterBinding with BoostFlutterBinding {}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Since many people mentioned no transition animation, this is because the previous example used [PageRouteBuilder],
  /// Actually this can be customized, not much related to Boost. For example, if I want to use iOS-like animation,
  /// I just need to write it as [CupertinoPageRoute] like below
  /// (Writing all as [MaterialPageRoute] also works, here we just use [CupertinoPageRoute] as an example)
  ///
  /// Note: If you need both pages to move during push,
  /// (like iOS native, where the previous page also moves left a bit during push)
  /// Then both pages must follow CupertinoRouteTransitionMixin
  /// Simply put, just make both pages CupertinoPageRoute
  /// Same applies if using MaterialPageRoute

  Map<String, FlutterBoostRouteFactory> routerMap = {
    'mainPage': (RouteSettings settings, String uniqueId) {
      return CupertinoPageRoute(
          settings: settings,
          builder: (_) {
            Map<String, Object> map = settings.arguments as Map<String, Object> ;
            String data = map['data'] as String;
            return MainPage(
              data: data,
            );
          });
    },
    'simplePage': (settings, uniqueId) {
      return CupertinoPageRoute(
          settings: settings,
          builder: (_) {
            Map<String, Object> map = settings.arguments as Map<String, Object>;
            String data = map['data'] as String;
            return SimplePage(
              data: data,
            );
          });
    },
  };

  Route<dynamic> routeFactory(RouteSettings settings, String uniqueId) {
    FlutterBoostRouteFactory func = routerMap[settings.name] as FlutterBoostRouteFactory;
    return func(settings, uniqueId);
  }

  Widget appBuilder(Widget home) {
    return MaterialApp(
      home: home,
      debugShowCheckedModeBanner: true,

      /// Must add builder parameter, otherwise showDialog etc. will have issues
      builder: (_, __) {
        return home;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterBoostApp(
      routeFactory,
      appBuilder: appBuilder,
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Object data});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Main Page')),
    );
  }
}

class SimplePage extends StatelessWidget {
  const SimplePage({Object data});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body:  Center(child: Text('SimplePage')),
    );
  }
}
```

Dart side integration is now complete

## Android Section

1. Add the following code in setting.gradle file, this step is to reference the flutter project. After adding, `Binding` will show red, ignore this for now, continue reading

```
setBinding(new Binding([gradle: this]))
evaluate(new File(
        settingsDir.parentFile,
        'flutter_module/.android/include_flutter.groovy'
))
include ':flutter_module'
project(':flutter_module').projectDir = new File('../flutter_module')
```

2. Then add the following code in app's build.gradle

```
implementation project(':flutter')
implementation project(':flutter_boost')
```

3. You also need to add the following content in the manifest file. Just paste it inside the `<application>` tag, at the same level as other `<activity>` tags

```xml
<activity
        android:name="com.idlefish.flutterboost.containers.FlutterBoostActivity"
        android:theme="@style/Theme.AppCompat"
        android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density"
        android:hardwareAccelerated="true"
        android:windowSoftInputMode="adjustResize" >

</activity>
<meta-data android:name="flutterEmbedding"
           android:value="2">
</meta-data>


```

Then click sync in the top right corner, it will start some download and sync process, wait for completion

4. Add `FlutterBoost` startup process in `Application` and set delegate

```java
public class App extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        FlutterBoost.instance().setup(this, new FlutterBoostDelegate() {
            @Override
            public void pushNativeRoute(FlutterBoostRouteOptions options) {
                // Here determine which page you want to navigate to based on options.pageName, here's a simple example
                Intent intent = new Intent(FlutterBoost.instance().currentActivity(), YourTargetAcitvity.class);
                FlutterBoost.instance().currentActivity().startActivityForResult(intent, options.requestCode());
            }

            @Override
            public void pushFlutterRoute(FlutterBoostRouteOptions options) {
                Intent intent = new FlutterBoostActivity.CachedEngineIntentBuilder(FlutterBoostActivity.class)
                        .backgroundMode(FlutterActivityLaunchConfigs.BackgroundMode.transparent)
                        .destroyEngineWithActivity(false)
                        .uniqueId(options.uniqueId())
                        .url(options.pageName())
                        .urlParams(options.arguments())
                        .build(FlutterBoost.instance().currentActivity());
                FlutterBoost.instance().currentActivity().startActivity(intent);
            }
        }, engine -> {
        });
    }
}
```

Android integration is now complete

## iOS Section

1. First go to your iOS directory, execute `pod init`, then execute `pod install` once

2. Open the created Podfile file, add the following code

```
flutter_application_path = '../flutter_module'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')
install_all_flutter_pods(flutter_application_path)
```

After adding, your Podfile should look similar to this

```
# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

flutter_application_path = '../flutter_module'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'BoostTestIOS' do
  use_frameworks!

  install_all_flutter_pods(flutter_application_path)

end
```

Then execute `pod install`, installation complete

3. Create `FlutterBoostDelegate` for preparation. The content here is fully customizable. Once you understand the meaning of each API, you can fully customize the code in each method. Below is just the default solution for most scenarios

```swift
class BoostDelegate: NSObject,FlutterBoostDelegate {

    /// The navigation controller you use for push
    var navigationController:UINavigationController?

    /// Table to store return results to flutter side
    var resultTable:Dictionary<String,([AnyHashable:Any]?)->Void> = [:];

    func pushNativeRoute(_ pageName: String!, arguments: [AnyHashable : Any]!) {

        // Can use parameters to control push or pop
        let isPresent = arguments["isPresent"] as? Bool ?? false
        let isAnimated = arguments["isAnimated"] as? Bool ?? true
        // Here determine which vc to generate based on pageName, here's a default one
        var targetViewController = UIViewController()

        if(isPresent){
            self.navigationController?.present(targetViewController, animated: isAnimated, completion: nil)
        }else{
            self.navigationController?.pushViewController(targetViewController, animated: isAnimated)
        }
    }

    func pushFlutterRoute(_ options: FlutterBoostRouteOptions!) {
        let vc:FBFlutterViewContainer = FBFlutterViewContainer()
        vc.setName(options.pageName, uniqueId: options.uniqueId, params: options.arguments,opaque: options.opaque)

        // Use parameters to control push or pop
        let isPresent = (options.arguments?["isPresent"] as? Bool)  ?? false
        let isAnimated = (options.arguments?["isAnimated"] as? Bool) ?? true

        // Set result for this page
        resultTable[options.pageName] = options.onPageFinished;

        // If present mode, or opaque mode, then need to open page in present mode
        if(isPresent || !options.opaque){
            self.navigationController?.present(vc, animated: isAnimated, completion: nil)
        }else{
            self.navigationController?.pushViewController(vc, animated: isAnimated)
        }
    }

    func popRoute(_ options: FlutterBoostRouteOptions!) {
        // If the currently presented vc is container, then execute dismiss logic
        if let vc = self.navigationController?.presentedViewController as? FBFlutterViewContainer,vc.uniqueIDString() == options.uniqueId{

            // There are two cases here, since UIModalPresentationOverFullScreen has lifecycle display issues
            // Manual calling is needed so that the underlying vc calls viewAppear related logic
            if vc.modalPresentationStyle == .overFullScreen {

                // Manually trigger page lifecycle with beginAppearanceTransition
                self.navigationController?.topViewController?.beginAppearanceTransition(true, animated: false)

                vc.dismiss(animated: true) {
                    self.navigationController?.topViewController?.endAppearanceTransition()
                }
            }else{
                // Normal case, dismiss directly
                vc.dismiss(animated: true, completion: nil)
            }
        }else{
            self.navigationController?.popViewController(animated: true)
        }
        // Otherwise directly execute pop logic
        // Here when popping, bring out the parameters and remove from result table
        if let onPageFinshed = resultTable[options.pageName] {
            onPageFinshed(options.arguments)
            resultTable.removeValue(forKey: options.pageName)
        }
    }
}
```

4. Initialize in `AppDelegate`'s `didFinishLaunchingWithOptions` method

```swift
// Create delegate, perform initialization
let delegate = BoostDelegate()
FlutterBoost.instance().setup(application, delegate: delegate) { engine in

}
```

## OHOS Section

Single UIAbility

The entire application has only one UIAbility, Flutter interface is hosted by FlutterPage

1. Bind Flutter with UIAbility

Bind Flutter in UIAbility's `onCreate`, `onDestroy`, `onWindowStageCreate`, `onWindowStageDestroy` lifecycle functions.

```typescript
async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
  FlutterManager.getInstance().pushUIAbility(this);
}

onDestroy(): void {
  FlutterManager.getInstance().popUIAbility(this);
}

onWindowStageCreate(windowStage: window.WindowStage): void {
  FlutterManager.getInstance().pushWindowStage(this, windowStage)
}

onWindowStageDestroy(): void {
  FlutterManager.getInstance().popWindowStage(this);
}
```

1. Initialize FlutterBoost

Since FlutterBoost will initialize the engine after calling setup, it's recommended to include GeneratedPluginRegistrant.getPlugins() when initializing optionsBuilder

- Current UIAbility inherits FlutterBoostDelegate
- Call `FlutterBoost.getInstance().setup` at the appropriate time (recommended onWindowStageCreate)

```typescript
export default class EntryAbility extends UIAbility implements FlutterBoostDelegate {
  // FlutterBoostDelegate override
  pushNativeRoute(options: FlutterBoostRouteOptions) {

  }
  // FlutterBoostDelegate override
  pushFlutterRoute(options: FlutterBoostRouteOptions) {

    router.pushUrl({
      url: 'pages/MyFlutterPage', params: {
        uri: options.getPageName(),
        params: options.getArguments(),
      }
    }).then(() => {
      console.info('Succeeded in jumping to the second page.')
    })
  }
  onWindowStageCreate(windowStage: window.WindowStage): void {

    // Initialize startup parameters (recommended to include GeneratedPluginRegistrant.getPlugins())
    const optionsBuilder: FlutterBoostSetupOptionsBuilder = new FlutterBoostSetupOptionsBuilder()
      .setPlugins(GeneratedPluginRegistrant.getPlugins());

    FlutterBoost.getInstance().setup(this, this.context, () => {
      // Engine initialization successful
    }, optionsBuilder.build())

  }
}
```
If you want a Promise-based setup function, please use `FlutterBoost.getInstance().setupSync`

1. Custom FlutterPage

Create a Page, add related `FlutterBoostEntry` and `FlutterPage` code

```typescript
@Entry
@Component
struct MyFlutterPage {
  private flutterEntry: FlutterBoostEntry | null = null;
  private flutterView?: FlutterView

  aboutToAppear() {
    this.flutterEntry = new FlutterBoostEntry(getContext(this), router.getParams());
    this.flutterEntry.aboutToAppear();
    this.flutterView = this.flutterEntry.getFlutterView();
    hilog.info(0x0000, "Flutter", "Index aboutToAppear===");
  }
  //2
  aboutToDisappear() {
    hilog.info(0x0000, "Flutter", "Index aboutToDisappear===");
    this.flutterEntry?.aboutToDisappear()
  }

  onPageShow() {
    hilog.info(0x0000, "Flutter", "Index onPageShow===");
    this.flutterEntry?.onPageShow()
  }
  // 1
  onPageHide() {
    hilog.info(0x0000, "Flutter", "Index onPageHide===");
    this.flutterEntry?.onPageHide()
  }

  build() {
    Stack() {
      FlutterPage({ viewId: this.flutterView?.getId() })
    }
  }

  // Intercept back button
  onBackPress(): boolean | void {
    FlutterBoost.getInstance().getPlugin()?.onBackPressed();
    return true;
  }
}
```

4. Navigate to Flutter Interface
   Later just use router to navigate to the page in step 3
```typescript

router.pushUrl({
  url: 'pages/MyFlutterPage', params: {
    uri: 'Write the route name registered on dart side here',
    params: 'Parameters to pass to the interface',
  }
}).then(() => {
  console.info('Succeeded in jumping to the second page.')
})
```

*Multi-tab Coexistence*

How to have multiple flutter interfaces coexist on multiple tabs.

```typescript

@Entry
@Component
struct EntryPage {
  @State currentIndex: number = 0;
  private flutterEntries: Array<FlutterBoostEntry> = [];

  build() {
    Column() {
      Tabs({
        index: this.currentIndex,
        barPosition: BarPosition.End
      }) {
        ForEach(bottomTabItems.getTabItems(), (item: TabItem) => {
          TabContent() {
            Column() {
              this.Content()
            }
          }
          .tabBar(this.CardTab(item))
        }, (item: TabItem, index?: number) => index + JSON.stringify(item))
      }
      .vertical(false)
      .barWidth("100%")
      .barHeight("56vp")
      .layoutWeight(1)
      .barMode(BarMode.Fixed)
      .align(Alignment.Center)
      .onChange((index: number) => {
        this.currentIndex = index;

        if (this.currentIndex == 1) {
          this.flutterEntries[0]?.aboutToAppear();
          this.flutterEntries[0]?.onPageShow();
          this.flutterEntries[1]?.onPageHide();
        } else if (this.currentIndex == 2) {
          this.flutterEntries[1]?.aboutToAppear();
          this.flutterEntries[1]?.onPageShow();
          this.flutterEntries[0]?.onPageHide();
        }
      })
    }
    .backgroundColor("#F1F3F5")
  }

  // Component lifecycle
  aboutToAppear() {
    console.info('MyComponent aboutToAppear');

    const firstFlutterEntry = new FlutterBoostEntry(getContext(this), {
      uri: 'firstFirst'
    });

    const secondFlutterEntry = new FlutterBoostEntry(getContext(this), {
      uri: 'flutterPage'
    });

    this.flutterEntries.push(firstFlutterEntry);
    this.flutterEntries.push(secondFlutterEntry);
  }

  // Component lifecycle
  aboutToDisappear() {
    console.info('MyComponent aboutToDisappear');
  }

  // Only components decorated with @Entry can call page lifecycle
  onPageShow() {
    console.info('Index onPageShow');
  }

  // Only components decorated with @Entry can call page lifecycle
  onPageHide() {
    console.info('Index onPageHide');
  }

  @Builder
  CardTab(item: TabItem) {
    Column() {
      Image(this.currentIndex === item.index ? item.imageActivated : item.imageOriginal)
        .width("21vp")
        .height("21vp")
        .objectFit(ImageFit.Contain)
        .margin({
          top: "4vp",
          bottom: "5.5vp"
        })
      Text(item.title)
        .fontSize("10fp")
        .fontColor(this.currentIndex === item.index ?
          "#007DFF" : "#66000000")
    }
    .justifyContent(FlexAlign.Center)
    .width("100%")
    .height("100%")
  }

  @Builder
  Content() {
    if (this.currentIndex === 0) {
      Column() {
        Button('Open FlutterEntry')
          .onClick(() => {
            router.pushUrl({ url: 'pages/MyFlutterPage', params: {
              uri: 'flutterPage',
              params: {}
            } }).then(() => {
              console.info('Succeeded in jumping to the second page.')
            })
          })
      }
    } else if (this.currentIndex === 1) {
      FlutterPage({ viewId: this.flutterEntries[0]?.getFlutterView()?.getId() })
    } else if (this.currentIndex === 2) {
      FlutterPage({ viewId: this.flutterEntries[1]?.getFlutterView()?.getId() })
    } else {
      Text("Content" + this.currentIndex)
        .fontSize("20fp")
        .fontColor(Color.Black)
        .fontWeight(500)
    }``
  }

  // Intercept back button
  onBackPress(): boolean | void {
    FlutterBoost.getInstance().getPlugin()?.onBackPressed();
    return true;
  }
}

```



All prerequisite content is now complete
