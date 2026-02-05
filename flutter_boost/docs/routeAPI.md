# Basic Route API

## Dart Section
### 1. Unified API for Opening New Pages
```dart
BoostNavigator.instance.push(
    "yourPage", //required
    withContainer: false, //optional
    arguments: {"key":"value"}, //optional
    opaque: true, //optional,default value is true
);

///or

Navigator.of(context).pushNamed('simplePage', arguments: {'data': _controller.text});

/// Anonymous routes cannot be used, boost currently cannot capture anonymous routes. Anonymous routes are using
/// forms like CupertinoPageRoute directly for push, which is not supported!!!
```

Parameter | Meaning | Optional
-------- | -----| -----
`name` | Page name in route table | NO
`withContainer` | Whether to pop with native container | YES
`arguments` | Parameters to pass to next page | YES
`opaque` | Whether page is opaque (mentioned again below) | YES

### 2. Opening Transparent Dialogs (Opening dialogs in Flutter)

- Flutter internal dialog without opening new container (Recommended)

```dart
/// First you need to specify the dialog page in your routeFactory route table like this
'dialogPage': (settings, uniqueId) {
    return PageRouteBuilder<dynamic>(

      /// For transparent dialog page this needs to be false
      opaque: false,

      /// Background mask color
      barrierColor: Colors.black12,
      settings: settings,
      pageBuilder: (_, __, ___) => DialogPage());
},

/// Then pop it like this
BoostNavigator.instance.push("dialogPage");

/// If you need to receive return parameters
final result = await BoostNavigator.instance.push("dialogPage");
```


- Flutter internal dialog with opening new container

Registration method for dialogPage in route table can be the same as above
```dart
 BoostNavigator.instance.push("dialogPage",
        withContainer: true,

        /// If opening new container, need to specify opaque as false
        opaque: false);
```


### 3. Close Page API
```dart
/// pop once
BoostNavigator.instance.pop(result);

/// pop twice, first needs await to wait
await BoostNavigator.instance.pop(result);
BoostNavigator.instance.pop(result);
```

Parameter | Meaning | Optional
-------- | -----| -----
`result` | Return parameters | YES
 - ##### Important note: If the Flutter page opened has no container (e.g., through native Navigator.push, or withContainer=false), then when popping, result can be any type; if the page opened is a Flutter page with container (i.e., withContainer=true) or a Native page, then result needs to be `Map<String, dynamic>` type.



## Android
### 1. Unified API for Opening New Pages
```java
FlutterBoostRouteOptions options = new FlutterBoostRouteOptions.Builder()
                .pageName("pageName")
                .arguments(new HashMap<>())
                .requestCode(1111)
                .build();
FlutterBoost.instance().open(options);
```


### 2. Close Page API (Less commonly used)
```java
FlutterBoost.instance().close(uniqueId);
```


### 3. Return Result to Previous Page When Page Closes
#### 3.1 Pass Parameters to Previous Native Page When Flutter Page Exits

FlutterBoostActivity example:
```java
// 1. Open Flutter page, wait for return result
Intent intent = new FlutterBoostActivity.CachedEngineIntentBuilder(FlutterBoostActivity.class)
        .backgroundMode(FlutterActivityLaunchConfigs.BackgroundMode.opaque)
        .destroyEngineWithActivity(false)
        .url("DialogPage")
        .urlParams(params)
        .build(this);
startActivityForResult(intent, REQUEST_CODE);

@Override
public void onActivityResult(int requestCode, int resultCode, Intent data) {
    // Handle return result
}
```

```dart
// 2. Close Flutter page, return result
InkWell(
child: Container(
    padding: const EdgeInsets.all(8.0),
    margin: const EdgeInsets.all(8.0),
    color: Colors.yellow,
    child: Text(
        'Pop with Navigator',
        style: TextStyle(fontSize: 22.0, color: Colors.blue),
    )),
// You can also use: Navigator.of(context).pop({'retval' : 'I am from dart...'})
onTap: () => BoostNavigator.instance.pop({'retval' : 'I am from dart...'}),
),
```

Note: For customization, please implement FlutterViewContainer's finishContainer interface yourself.

#### 3.2 Pass Parameters to Previous Flutter Page When Native Page Exits

```dart
// 1. Open a Native page from Flutter page, and handle return result
InkWell(
child: Container(
    padding: const EdgeInsets.all(8.0),
    margin: const EdgeInsets.all(8.0),
    color: Colors.yellow,
    child: Text(
        'open native page',
        style: TextStyle(fontSize: 22.0, color: Colors.black),
    )),
onTap: () => BoostNavigator.instance
    .push("ANativePage") // Native page route
    .then((value) => print('retval:$value')),
),
```

```java
// 2. Return result when Native page exits
@Override
public void finish() {
    Intent intent = new Intent();
    intent.putExtra("msg","This message is from Native!!!");
    intent.putExtra("bool", true);
    intent.putExtra("int", 666);
    setResult(Activity.RESULT_OK, intent);  // Return result to dart
    super.finish();
}
```

#### 3.3 Pass Parameters to Previous Flutter Page When Flutter Page Exits
```dart
// 1. Open a Flutter page, and handle return result
InkWell(
child: Container(
    padding: const EdgeInsets.all(8.0),
    margin: const EdgeInsets.all(8.0),
    color: Colors.yellow,
    child: Text(
        'open transparent widget',
        style: TextStyle(fontSize: 22.0, color: Colors.black),
    )),
onTap: () {
    // When withContainer is false, you can also use native Navigator
    final result = await BoostNavigator.instance.push("AFlutterPage",
        withContainer: true, opaque: false);
},
),

// 2. Close page and return result
// You can also use native Navigator here
onTap: () => BoostNavigator.instance.pop({'retval' : 'I am from dart...'}),
```

## iOS

### 1. Unified API for Opening New Pages

```swift
let options = FlutterBoostRouteOptions()
options.pageName = "mainPage"
options.arguments = ["key" :"value"]

// Whether page is opaque (for transparent dialog scenarios), if not set, default is true
options.opaque = true

// This is the callback for push operation completion, NOT the callback for page close!!!
options.completion = { completion in
    print("open operation is completed")
}

// This is the callback for page close and data return, actual callback needs to be based on popRoute in your Delegate
options.onPageFinished = { dic in
    print(dic)
}

FlutterBoost.instance().open(options)
```

### 2. Close Page API (Less commonly used)
```swift
FlutterBoost.instance().close(uniqueId)
```

### 3. Native Parameters Return to Flutter
```swift
// Here pageName is the pageName of this native page you pushed, not the previous flutter page's pageName
// This statement does not exit the page
FlutterBoost.instance().sendResultToFlutter(withPageName: "pageName", arguments: ["key":"value"])
```

### Next Step: [Lifecycle API](https://github.com/alibaba/flutter_boost/blob/master/docs/lifecycle.md)
