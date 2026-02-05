# Custom Event Passing API

This section is equivalent to letting developers skip the manual bridging functionality, allowing event passing through event identifier key and parameter map


## Flutter Side Usage

 - Receive messages
```dart
/// Declare an object to store the callback
VoidCallback removeListener;

/// Add event responder, listen for events sent from native to flutter
removeListener = BoostChannel.instance.addEventListener("yourEventKey", (key, arguments) {
  /// deal with your event here
  return;
});

/// Then remove the listener when exiting (e.g., in dispose)
removeListener?.call();
```

 - Send messages to native
```dart
BoostChannel.instance.sendEventToNative("eventToNative",{"key1":"value1"});
```

## iOS Side Usage

 - Receive messages
```swift
// Similarly declare an object to store the remove function
var removeListener:FBVoidCallback?

// Register event listener here, listen for events sent from flutter to iOS
self.removeListener =  FlutterBoost.instance().addEventListener({[weak self] key, dic in
    // Note: if self holds removeListener, and this closure also has self, use weak self
    // Otherwise there's self->removeListener->self circular reference
    
    // Handle your event here
    
}, forName: "event")

// Unregister when exiting (e.g., in deinit/dealloc)
removeListener?()
```

- Send messages to flutter
```swift
FlutterBoost.instance().sendEventToFlutter(with: "event", arguments: ["data":"event from native"])
```

## Android Side Usage

 - Receive messages

```java
EventListener listener = (key, args) -> {
    // deal with your event here      
};
ListenerRemover remover = FlutterBoost.instance().addEventListener("event", listener);

// Finally remove listener when cleaning up (e.g., in onDestroy)
remover.remove();
```

- Send messages to flutter
```java
Map<Object,Object> map = new HashMap<>();
map.put("key","value");
FlutterBoost.instance().sendEventToFlutter("eventToFlutter",map);
```
