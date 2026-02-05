# Lifecycle API Section (This section only has Flutter side, no native implementation)

## 1. Global Listener API

Generally you can add a global observer at the main stage
```dart
void main() {
  /// Add global lifecycle listener class
  PageVisibilityBinding.instance.addGlobalObserver(AppLifecycleObserver());
  runApp(MyApp());
}
```

Specific implementation of `AppLifecycleObserver` is as follows
```dart
/// Global lifecycle listener example
class AppLifecycleObserver with GlobalPageVisibilityObserver {
  @override
  void onBackground(Route route) {
    super.onBackground(route);
    print("AppLifecycleObserver - onBackground");
  }

  @override
  void onForeground(Route route) {
    super.onForeground(route);
    print("AppLifecycleObserver - onForground");
  }

  @override
  void onPagePush(Route route) {
    super.onPagePush(route);
    print("AppLifecycleObserver - onPagePush");
  }

  @override
  void onPagePop(Route route) {
    super.onPagePop(route);
    print("AppLifecycleObserver - onPagePop");
  }

  @override
  void onPageHide(Route route) {
    super.onPageHide(route);
    print("AppLifecycleObserver - onPageHide");
  }

  @override
  void onPageShow(Route route) {
    super.onPageShow(route);
    print("AppLifecycleObserver - onPageShow");
  }
}
```

## 2. Single Page Listener
```dart
/// Single page lifecycle example
class LifecycleTestPage extends StatefulWidget {
  const LifecycleTestPage({Key key}) : super(key: key);

  @override
  _LifecycleTestPageState createState() => _LifecycleTestPageState();
}

class _LifecycleTestPageState extends State<LifecycleTestPage>
    with PageVisibilityObserver {
  @override
  void onBackground() {
    super.onBackground();
    print("LifecycleTestPage - onBackground");
  }

  @override
  void onForeground() {
    super.onForeground();
    print("LifecycleTestPage - onForeground");
  }

  @override
  void onPageHide() {
    super.onPageHide();
    print("LifecycleTestPage - onPageHide");
  }

  @override
  void onPageShow() {
    super.onPageShow();
    print("LifecycleTestPage - onPageShow");
  }

  @override
  void initState() {
    super.initState();

    /// Please register in didChangeDependencies instead of initState
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Register listener
    PageVisibilityBinding.instance.addObserver(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    /// Remove listener
    PageVisibilityBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ...;
  }
}
```

### Additional Notes
 - At the page level, there are no `push` and `pop` events. Initialization logic should be written directly in `initState`, and cleanup logic should be written in `dispose`

 - `onPageShow` corresponds to Android `onResume`, iOS `viewDidAppear`
 - `onPageHide` corresponds to Android `onStop`, iOS `viewDidDisappear`
