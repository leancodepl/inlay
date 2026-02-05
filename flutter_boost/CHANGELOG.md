## NEXT

## 4.6.5
1. [dart] Support business side to get whether current flutter page is external route flutter page

## 4.6.4
1. [dart] Add demo to verify extended_image plugin's image swipe left/right, zoom and other gesture operations
2. [ohos] Provide external interface for business side to determine if current flutterEntry is at topContainer

## 4.6.3
1. Revert "Support ACB jump route business scenario" Reason: After discussion, it's considered that this scenario in Quark business can be implemented directly on business side, no need to modify boost internal, to minimize interference with boost internal logic, decided to revert this commit
2. [ohos] Simplify implementation of 'Fix page freeze when continuously opening same dialog and going back'
3. [ios] Fix surfaceUpdated being executed multiple times when opening a new container
4. Revert "[ios] Fix surfaceUpdated being executed multiple times when opening a new container" Reason: This modification has bad case, need different implementation
5. [ios] Re-implement "Fix surfaceUpdated being executed multiple times when opening a new container"

## 4.6.2
1. Update README and FAQ
2. [ohos] Fix log unable to serialize BigInt issue
3. Support ACB jump route business scenario

## 4.6.1
1. [ohos] Solve auto split screen issue when app switches to landscape
2. [ohos] Solve dialog transparent popup re-executing enter animation when returning from fullscreen page
3. [ohos,dart] Native side cancel business custom RouterOptions implementation, optimize page return parameter interface usability, fix possible parameter passing failure when native page returns to flutter page
4. [ohos] Allow business to implement their own page pop logic
5. [dart] Optimize PlatformView example code
6. [dart] Add hidden platformview example code
7. [dart] Complete image format test cases
8. Revert: "[ohos,dart] Native side cancel business custom RouterOptions implementation, optimize page return parameter interface usability..."
9. [ohos] Fix page freeze when continuously opening same dialog and going back
10. [ohos,dart] Optimize page return parameter interface usability, fix possible parameter passing failure when native page returns to flutter page

## 4.5.11
1. [dart] Add `SystemChrome.setPreferredOrientations` test case
2. [ohos] Fix transparent popup freeze and related issues when covered by other fullscreen page, add dialog related scene example demo
3. [ohos] Solve onPageHide call asymmetry with onPageShow in FlutterBoostEntry
4. [ohos] Adapt to latest PlatformView solution
5. [ohos] Solve portrait/landscape orientation not taking effect issue
6. [ohos] Solve data retrieval failure from system clipboard due to permission issues
7. [ohos] Solve flutter page flickering under transparent popup when going back

# 4.5.10
1. [dart] Add HDR/HEIC/HEIF/TIFF/WBMP/WEBP and other image format test cases
2. [ohos] Solve freeze issue when transparent popup page switches to background or is covered by Native page

# 4.5.9
1. [ohos] Fully support HarmonyOS page return parameter passing, including all four cases (native to native, Flutter to native, native to Flutter, Flutter to Flutter)
2. [ohos] Add foreground/background event notification logic
3. [ohos] Allow business to control debug log output
4. [ohos] Solve page freeze issue during foreground/background switch in transparent popup scenario

# 4.5.8
1. [ohos] HarmonyOS page return parameter support
2. [ohos] Fix Tab scenario log inexplicably reporting 'Missing params' issue
3. [ohos] Refactor ets layer page route parameter passing logic, support native page to get business parameters from previous native or flutter page
4. [ohos] Adapt to api12 & DevEco-5.0.3.300

# 4.5.7
1. [ohos] Issue fixed, unified to use HarmonyOS community git dependency
2. Update FlutterBoost version description
3. Add clipboard example
4. [ohos] Update FlutterBoost project structure

# 4.5.6
1. [ohos] Take over FlutterView engine binding timing, solve Tab scenario display abnormal issue, avoid redundant attach/detach
2. [ohos] Solve page freeze after returning from transparent popup

# 4.5.5
1. [ohos] Fix image_pick plugin example
2. [ohos] Simplify HarmonyOS example code
3. [ohos] Unofficially approved federated plugins need to be specified separately in pubspec
4. [ohos] Fix WebView example code
5. [ohos] Use Navigation, solve semi-transparent popup not showing through issue
6. [ohos] Fix page back abnormal issue after using Navigation
7. [ohos] Code refactoring for future optimization
8. [ohos] Default to explicitly use surface mode
9. Add SafeArea test case
10. [ohos] Set fullscreen window
11. [ohos] Fix transparent popup showing through abnormal issue
12. [ohos] Add PlatformView test case
13. [ohos] Update plugin import method

## 4.5.4
1. [ohos] Support passing startup parameters and dart entry parameters
2. [ohos] Update plugin registration logic (BREAKING CHANGE)

## 4.5.3
1. [ohos] Remove unnecessary lifecycle notifications
2. [ohos] Fix getStackFromHost/saveStackToHost related message channel code error
3. [ohos] Example add logic to open HarmonyOS native page
4. [ohos] Fix `hot restart` white screen issue

## 4.5.2
1. [ohos] Solve page switch flickering issue

## 4.5.1
1. [ohos] Temporarily fix tab content first display abnormal issue

## 4.5.0
1. Adapt to HarmonyOS

## 4.4.2
1. Downgrade AGP version from 7.0.4 to 3.3.0

## 4.4.1
1. Revert: "Fix page freeze caused by fast internal route switching"

## 4.4.0
1. Expose updateSystemUIOverlays method to business
2. Improve SystemUiOverlayStyle Demo
3. When creating new container, use previous container's SystemUiOverlayStyle by default to configure new container's status bar, navigation bar
4. Fix page freeze caused by fast internal route switching

## 4.3.1
1. Uniform iOS code style.
2. Update issue submission template
3. fix: Fix 6.0 AccessibilityBridge.release()' on a null object reference
4. [ios] Solve pop parameter not returning issue

## 4.3.0
1. Improve codes in Android. (#1855)
2. Improve codes (#1856)
3. [Android] Solve stretched (or compressed) page flash during back after landscape/portrait switch (#1857)
4. Support passing through Dart entrypoint arguments (#1858)
5. Revert: "[Android] Solve stretched (or compressed) page flash during back after landscape/portrait switch (#1857)" (#1859)

## 4.2.3
1. Add custom `appBuilder` example (#1827)
2. [Android] fix flutterfragment fast switching causes non-rendering bug (#1830)
3. Fixes the compilation errors when running the example with Flutter 3.10.0 (#1838)
4. Solve issue where return parameters cannot be passed to previous page when opening dialog and closing then closing page (#1846)
5. Fix removeWithResult interface not returning result issue (#1850)
6. Add license headers (#1851)
7. Expose interface to allow business to enable Android internal log output for debugging (#1853)

## 4.2.2
1. [Android] Use stack to record active Activity, solve topActivity possibly being null in some scenarios (#1810)
2. Add Test Cases for ImageCache. (#1822)
3. Fix type conversion errors and add a prompt for unregistered routes. (#1823)
4. Fix unnecessary rebuild of previous page when going back (#1824)

## 4.2.1
1. Add hero animation demo. (#1756)
2. [ios] Fixes the warning that the license file does not exist (#1759)
3. Handle pushReplacement generic conversion error (#1758)
4. Update license link (#1754)
5. fix(FlutterTextureHooker): Fix setSurfaceTexture exception issue (#1774)
6. Add PlatformView scenario for semi-transparent popup (#1799)
7. Open _containers in FlutterBoostAppState (#1800)
8. Fix partial push scenario conflict with gesture causing two pops to trigger
9. [Android] Solve FlutterBoostFragment possibly flashing previous page during switch (#1807)

## 4.2.0
1. [Android] Fixes HybridCompositon does not work (#1743)
2. Add pigeon commands to script file. (#1744)
3. [ios] Use a screen edge pan gesture to go back to the previous page of a non-container page. (#1751)

## 4.1.1
1. [Android] Fix FlutterFragment possibly covering NativeFragment Bug (#1736)
2. Update README_CN.md (#1731)

## 4.1.0
1. [Android]fix popUntil not working (#1718)
2. Add demo for afterimage test
3. [Android] Keep lifecycle behavior consistent with pure Flutter app: pause frame scheduling when app switches to background, solve animation afterimage issue. [Note] App must ensure accuracy of foreground/background notification events (onBackground/onForeground) (take over via dispatchBackForegroundEvent interface when necessary), otherwise page freeze may occur;
4. [Android] Open didFragmentShow and didFragmentHide to subclass (#1726)

## 4.0.4
1. Fix onPostPush and onPostPush type cast failure (#1707)
2. [Android] Expose exception caused by obfuscation early, with clear guidance

## 4.0.3
1. Fix possible type conversion error in `addEventListener` function

## 4.0.2
1. Add dual_screen test case
2. [Android] Restore detachFromFlutterEngine override logic, solve null pointer crash issue

## 4.0.1
1. Fix runtime type error in some scenarios, e.g. hot restart
2. Remove debug info
## 4.0.0
1. Support Flutter 3.0
2. Migrate example code to null safety

## 3.1.0
1. [Android] Remove unnecessary fallback solution, solve Native page return value loss issue
2. [Android] Add counter test case, verify page refresh issue
3. Support null safety (based on Flutter2.5.x)
4. [Android] Remove AndroidX dependency

## v3.0-release.2
1. Fix memory leak issue when flutter home opens page A, opens page B and returns to home
2. [bugfix] 1. Solve assertion error caused by async (#1583); 2. Modify test case, solve test page being intercepted issue
3. [Android] Improve PlatformView test case: 1. Add complex Native animation scenario; 2. Support intent to open test page, convenient for automation testing;
4. Add simple WebView test scenario
5. Change interceptor internal implementation to synchronous, avoid timing related issues

## v3.0-release.1
1. [ios] Add platform view test case (#1546)
2. [Android] In Fragment usage scenario, onHiddenChanged/setUserVisibleHint may be called before onCreateView (#1456)
3. [featurePR] Make FlutterBoost's FlutterBoostFragment#finishContainer method allow subclass to customize container close logic (#1565)
4. fix(Android): FlutterBoost opening FlutterBoostFragment page causes status bar color abnormal (#1570)
5. Interceptor refactoring: (#1583)
6. Rename example_new to example_new_for_ios

Breaking Change
1. Interceptor refactoring, see https://github.com/alibaba/flutter_boost/pull/1583

## v3.0-preview.18
1. Fix black screen caused by hot restart (#1537)
2. feat: Android expose popRoute delegate callback (#1531)
3. Change runtime exception to log output (#1541)
4. BoostContainer add backPressedHandler for custom back key functionality
5. Support creating engine via FlutterEngineProvider
6. Optimize example

## v3.0-preview.17
1. [Android] Fix activity leak in specific scenario
2. [Android] Fix FlutterEngine null pointer exception (#1471)
3. [flutter] Provide cached widget component BoostCacheWidget, can solve page rebuild issue during push process (#1486)
4. [iOS] Modify podspec xcconfig to pod_target_xcconfig, avoid modifying host project compile configuration (#1507)

## v3.0-preview.16
1. [Android] Fix activity leak in specific scenario (#1444)
2. [Android] Fix Fragment crash in specific usage scenario (#1450)
3. popUntil using containers list cannot guarantee order, will cause containers disorder during sync popRoute process. Need to clone queue in advance to guarantee (#1462)
4. [dart] Fix white screen issue when first visiting flutter page on app launch

## v3.0-preview.15
1. [ios] Expose flutter page resource release API externally (#1443)
2. [Android] When switching back to FlutterFragment from Native page, restore Dart perspective system chrome style, solve immersive status bar display issue

## v3.0-preview.14
1. [ios] Fix rendering error when app is put to background then launched via deeplink to enter Flutter page while applicationState is still in inActive state (#1442)

## v3.0-preview.13
1. [flutter] Fix timing issue of function calls when performing operations after engine startup but before flutter side has finished loading (#1415)
2. [Android] Fix Widget with onWillPop callback not being able to go back (#1411)

## v3.0-preview.12
1. [iOS] Consolidate iOS gesture control methods to BoostChannel as common methods, and dynamically disable and enable gestures in container's show listener
2. [flutter] Update example and default appBuilder implementation, pass builder parameter to avoid showDialog closing page instead of dialog
3. [flutter] Fix route order error in extreme cases

## v3.0-preview.11
1. [flutter] Let NavigatorExt take over pushNamed method
2. [flutter] Add tab mode example, delete unused lifecycle on iOS side, avoid push during initialization phase, solve tab white screen issue during initialization
3. [iOS] Advance event listener registration timing, and null check block when deleting, avoid crash

## v3.0-preview.10
1. [iOS] Provide engine warm-up functionality, avoid brief white/black screen when first entering flutter page, and font size jumping
2. [iOS] Single VC, multi flutterPage scenario, dynamically control container gesture swipe, when there are multiple pages internally, swipe will go through flutter internal swipe logic, avoid swipe taking away entire container when there are multiple pages
3. [dart] Update example code, show how to have transition animation when navigating within single container (e.g. iOS push effect)

## v3.0-preview.9
1.  [Android] Solve transparent popup background incorrect issue due to Android Q lifecycle callback abnormal in background switch scenario (#1288)
2.  [Android] Add engine release interface (#1291)

## v3.0-preview.8
1. [Android] Solve semi-transparent popup background black/white screen, parameter loss, permission request failure, and image_picker plugin unavailable issues in specific scenarios
2. [Android] Fix FlutterBoostActivity and FlutterBoostFragment not receiving permission request result bug
3. Solve iOS dismissViewController completion async callback event incomplete issue
4. [Android] Adapt page transparency parameter, add test case (#1265)
5. [Android] fix #1264 Fix bug where FlutterboostActivity cannot receive onActivityResult callback result due to commit #1250

## v3.0-preview.7
1. [Android] Solve PlatformViewsChannel disconnect issue when previous page destroys causing current page issue (#1250)
2. Hfix #1229 Fix example issue where when pushing to background from Flutter page and coming back to foreground, top page is Native page
3. Fix single engine multi VC issue: 1. updateViewportMetrics being called by multiple VCs when keyboard is invoked 2. Crash in Tab initialization scenario
4. Fix FlutterBoostFragment navigating to new FlutterBoostFragment, returning to previous FlutterFragment not responding to click events


## v3.0-preview.6
1.[iOS] Fix iOS opening Flutter page then closing not going through dispose logic issue
2.[Android] Solve setSystemUIOverlayStyle not taking effect issue
3.[Android] Enable state restoration by default

## v3.0-preview.5
1. Native side code refactoring
  a. uniqueId creation method consistent with Dart side
  b. Remove ContainerShadowNode abstract code
  c. Remove unnecessary engineId parameter when creating Flutter container
2. open method implements custom configuration parameters, enhance extensibility
3. [Consistency] Android side abstract FlutterContainerManager concept
4. Native onActivityResult return parameter to Flutter refactoring
5. Add thread check, ensure engine run on main thread, allow business to setup boost in sub-thread
6. [android] Fix multiple Fragments using same FlutterView in Tab scenario, and solve Fragment first display not correctly switching surface issue
7. FlutterBoostFragment optimization
8. [android] When FlutterFragment's onCreateView callback, temporarily don't attach to engine
9. iOS side transparency capability provided
10. Add example3.0
11. Fix page freeze after FlutterFragment exits for container page below
12. For easier business upgrade from 2.0 to 3.0, provide optional argument parameter for remove interface
13. [dart,Android,iOS] All provide custom event sending mechanism, events can be passed bidirectionally
14. [Android] Allow business to reuse pre-created engine
15. FIXED: HeroController.didPush assert(navigator != null) null exception
16. Ensure onPageShow event can be called when page is created
17. PageVisibility no longer provides create and destroy methods, also onPageCreate and onPageDestroy renamed to onPagePush and onPagePop
18. FIXED: Same container provides multiple FlutterViews, business layer using remove(uniqueId) to remove non-first flutterview by specified id fails
19. Boost takes over handleAppLifecycleStateChanged, let Flutter lifecycle align with app foreground/background
20. BoostNavigator add pushReplacement method, also fix pop and findContainerById logic
21. Filter internal route events where RouteSettings.name is null, like dialog and other non-page route events, otherwise affects normal page lifecycle
22. [Consistency] iOS side FBFlutterContainerManager unified with Android, FLutterBoostPlugin lifecycle related logic unified
23. Adjust Flutter Engine initialization flow, avoid timing issues with plugin registration using async method
24. Support closing container page through native Navigator
25. Refactor internal route Pop result return logic
26. [Android] Fix onPageHide event not triggered in specific scenarios (e.g., ViewPager2)

Breaking Change
1. For future Delegate extensibility, add FlutterBoostRouteOptions concept for parameter encapsulation, Delegate's push and pop parameter passing depends on this object

See details:
https://github.com/alibaba/flutter_boost/commit/14a3be59f97cad24bdba8663a79f3d17359641df
https://github.com/alibaba/flutter_boost/commit/c085258e09b79dc6c3660d384409c50e2497ef4b
https://github.com/alibaba/flutter_boost/commit/ce48530ad7114703d3a8dfb02e4e32543c9aaa10
https://github.com/alibaba/flutter_boost/commit/47676230f21472c28791660ec93515f41d4f6c2f

2. BoostNavigator's pop interface changed to async
https://github.com/alibaba/flutter_boost/commit/d2d1fdc100dee34085b76d597194b93309e0cd0f

3. PageVisibility no longer provides create and destroy methods, also onPageCreate and onPageDestroy renamed to onPagePush and onPagePop
Code previously in onPageCreate and onPageDestroy should be written in initState and dispose
https://github.com/alibaba/flutter_boost/commit/e2f15b234260ede810e943c4f8248fd07fce6414

4. Boost takes over handleAppLifecycleStateChanged, let container count determine Flutter's resume and pause state
Please refer to integration documentation for BoostFlutterBinding usage
https://github.com/alibaba/flutter_boost/commit/173c910ff8ed971eacfa1a263745921ae5cd5689
https://github.com/alibaba/flutter_boost/commit/abc2598f48dbcbeabf48057eec6d7737b0e21989


## v3.0-beta.11
1. Fix transparent page background being previous Container issue
2. Rewrite BoostContainerWidget equality method, avoid framework layer rebuilding existing pages

## v3.0-beta.10
1. BoostContainer refactoring, fix UI not refreshing when opening and closing pages in container

## v3.0-beta.9
1. Add foreground/background callback interface
2. Add callback capability for when native opens flutter page, after open operation completes

Breaking Change:
 [iOS] Add callback capability for when native opens flutter page, after open operation completes: https://github.com/alibaba/flutter_boost/commit/7f55728955b0afcdbaba5a17543e9dbdf1c24e65
Due to some business parties needing to know if page animation is complete, need to get present's completion callback,
therefore changed
- (void) pushFlutterRoute:(NSString *) pageName uniqueId:(NSString *)uniqueId arguments:(NSDictionary *) arguments
to
- (void) pushFlutterRoute:(NSString *) pageName uniqueId:(NSString *)uniqueId arguments:(NSDictionary *) arguments completion:(void(^)(BOOL)) completion;

## v3.0-beta.8
1. Provide flutter_boost.dart as external interface
2. BoostNavigator related API and implementation modifications
3. Solve _pendingResult possibly not completing issue
4. Add pre-interceptor capability
5. Solve all pages in page stack rebuilding during push and pop issue
6. Use effective_dart package provided linter rules file

## v3.0-beta.7
1. Lifecycle implementation adjustment
2. Solve Android side lifecycle event duplication in specific scenarios
3. Add custom startup parameter setting entry
4. Add page back parameter passing capability

Breaking Change:
page create and destroy event adjustment: https://github.com/alibaba/flutter_boost/commit/62c88805bf08606805e13254170691d2bc00bd4a
Due to lifecycle implementation change, PageVisiblityObserver's onPageShow and onPageHide methods no longer include isForegroundEvent and isBackgroundEvent parameters

## 1.12.13+2
  Fixed bugs

## 1.12.13
  Supported Flutter sdk 1.12.13

## 1.9.1+2

  Rename the version number and start supporting androidx by default, Based on the flutter 1.9.1 - hotfixs。
  fixed bugs

## 0.1.66

  Fixed bugs

## 0.1.64

  Fixed bugs

## 0.1.63

  android:
  Fixed bugs

  iOS:
  no change

## 0.1.61

  android:
  Fixed bugs

  iOS:
  no change

## 0.1.60

A better implementation to support Flutter v1.9.1+hotfixes

Change the content
android:

1. based on the v1.9.1+hotfixes branch of flutter
2. Solve major bugs, such as page parameter passing
3. Support platformview
4. Support androidx branch :feature/flutter_1.9_androidx_upgrade
5. Resolve memory leaks
6. Rewrite part of the code
7. API changes
8. Improved demo and added many demo cases

ios:

1.based on the v1.9.1+hotfixes branch of flutter
2.bugfixed



## 0.1.5
The main changes are as following:
1. The new version do the page jump (URL route) based on the inherited FlutterViewController or Activity. The jump procedure will create new instance of FlutterView, while the old version just reuse the underlying FlutterView
2. Avoiding keeping and reusing the FlutterView, there is no screenshot and complex attach&detach logical any more. As a result, memory is saved and black or white-screen issue occured in old version all are solved.
3. This version also solved the app life cycle observation issue, we recommend you to use ContainerLifeCycle observer to listen the app enter background or foreground notification instead of WidgetBinding.
4. We did some code refactoring, the main logic became more straightforward.

## 0.0.1

* TODO: Describe initial release.


### API changes
From the point of API changes, we did some refactoring as following:
#### iOS API changes
1. FlutterBoostPlugin's startFlutterWithPlatform function change its parameter from FlutterViewController to Engine
2.
**Before change**
```objectivec
FlutterBoostPlugin
- (void)startFlutterWithPlatform:(id<FLBPlatform>)platform onStart:(void (^)(FlutterViewController *))callback;
```

**After change**

```objectivec
FlutterBoostPlugin2
- (void)startFlutterWithPlatform:(id<FLB2Platform>)platform
                         onStart:(void (^)(id<FlutterBinaryMessenger,
                                           FlutterTextureRegistry,
                                           FlutterPluginRegistry> engine))callback;

```

2. FLBPlatform protocol removed flutterCanPop, accessibilityEnable and added entryForDart
**Before change:**
```objectivec
@protocol FLBPlatform <NSObject>
@optional
//Whether to enable accessibility support. Default value is Yes.
- (BOOL)accessibilityEnable;
// Whether flutter module can still pop
- (void)flutterCanPop:(BOOL)canpop;
@required
- (void)openPage:(NSString *)name
          params:(NSDictionary *)params
        animated:(BOOL)animated
      completion:(void (^)(BOOL finished))completion;
- (void)closePage:(NSString *)uid
         animated:(BOOL)animated
           params:(NSDictionary *)params
       completion:(void (^)(BOOL finished))completion;
@end
```
**After change:**
```objectivec
@protocol FLB2Platform <NSObject>
@optional
- (NSString *)entryForDart;

@required
- (void)open:(NSString *)url
   urlParams:(NSDictionary *)urlParams
        exts:(NSDictionary *)exts
      completion:(void (^)(BOOL finished))completion;
- (void)close:(NSString *)uid
       result:(NSDictionary *)result
         exts:(NSDictionary *)exts
   completion:(void (^)(BOOL finished))completion;
@end
```

#### Android API changes
Android mainly changed the IPlatform interface and its implementation.
It removed following APIs:
```java
Activity getMainActivity();
boolean startActivity(Context context,String url,int requestCode);
Map getSettings();
```

And added following APIs:

```java
void registerPlugins(PluginRegistry registry);
void openContainer(Context context,String url,Map<String,Object> urlParams,int requestCode,Map<String,Object> exts);
void closeContainer(IContainerRecord record, Map<String,Object> result, Map<String,Object> exts);
IFlutterEngineProvider engineProvider();
int whenEngineStart();
```
