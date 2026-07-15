# inlay_compose

![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)
[![inlay_compose pub.dev badge](https://img.shields.io/pub/v/inlay_compose)](https://pub.dev/packages/inlay_compose)

Jetpack Compose integration for the [inlay](https://pub.dev/packages/inlay) add-to-app framework. Embed inlay Flutter screens and dialogs directly in Compose UIs with typed results.

This is a separate package so that projects not using Compose depend only on `inlay` - the core plugin pulls in no Compose transitive dependencies. Android-only.

## Setup

Add it next to `inlay` in your Flutter module's `pubspec.yaml`:

```yaml
dependencies:
  inlay: ^0.1.1
  inlay_compose: ^0.1.1
```

## Embed a Flutter screen

`InlayFlutterScreen` renders an inlay Flutter page as a regular Compose destination:

```kotlin
import co.leancode.inlay.compose.InlayFlutterScreen

NavHost(navController, startDestination = "home") {
    composable("home") { HomeScreen() }

    composable("counter") {
        InlayFlutterScreen(
            route = CounterPage(seed = null),
            modifier = Modifier.fillMaxSize(),
            onResult = { count ->
                // count: Long? - already decoded
            },
        )
    }
}
```

When Flutter calls `pop()`, the screen integrates with Compose Navigation's back stack via `onBackPressedDispatcher`. `onResult` is invoked exactly once - with the result the page pops with, or `null` when the destination leaves the composition without one.

## Show a Flutter dialog

`InlayFlutterDialog` is state-driven, the Compose counterpart of SwiftUI's `.inlayDialog` modifier. While `isPresented` is `true`, a transparent dialog window is shown over the Activity and Flutter renders the dialog content (barrier, animation, positioning):

```kotlin
import co.leancode.inlay.compose.InlayFlutterDialog

var showDialog by remember { mutableStateOf(false) }
var lastResult by remember { mutableStateOf<String?>(null) }

Button(onClick = { showDialog = true }) { Text("Delete") }

InlayFlutterDialog(
    isPresented = showDialog,
    route = ConfirmDeleteDialog(itemId = "42"),
    onDismissRequest = { showDialog = false },
    onResult = { confirmed ->
        lastResult = confirmed?.toString() // confirmed: Boolean? - already decoded
    },
)
```

Do **not** wrap `InlayFlutterDialog` in a Compose `Dialog` or a Compose Navigation `dialog()` destination - it manages its own window (and a `FragmentManager` cannot attach fragments inside a Compose dialog window). `onDismissRequest` fires when the dialog goes away for any reason (Flutter pop, barrier tap, back); flip `isPresented` back to `false` there.

## Documentation

- [Navigation guide](https://github.com/leancodepl/inlay/blob/main/docs/navigation.md) - the full navigation model, including the Compose sections
- [Compose example](https://github.com/leancodepl/inlay/blob/main/example/example_android/app/src/main/java/co/leancode/inlay/example/android/ComposeActivity.kt) - a working NavHost mixing native and Flutter destinations

---

## 🛠️ Maintained by LeanCode

<div align="center">
  <a href="https://leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=inlay">
    <img src="https://leancodepublic.blob.core.windows.net/public/wide.png" alt="LeanCode Logo" height="100" />
  </a>
</div>

This package is built with 💙 by **[LeanCode](https://leancode.co?utm_source=github.com&utm_medium=referral&utm_campaign=inlay)**.
We are **top-tier experts** focused on Flutter Enterprise solutions.

### Why LeanCode?

- **Creators of [Patrol](https://patrol.leancode.co/?utm_source=github.com&utm_medium=referral&utm_campaign=inlay)** – the next-gen testing framework for Flutter.

- **Production-Ready** – We use this package in apps with millions of users.
- **Full-Cycle Product Development** – We take your product from scratch to long-term maintenance.

<div align="center">
  <br />

**Need help with your Flutter project?**

[**👉 Hire our team**](https://leancode.co/get-estimate?utm_source=github.com&utm_medium=referral&utm_campaign=inlay)
&nbsp;&nbsp;•&nbsp;&nbsp;
[Check our other packages](https://pub.dev/packages?q=publisher%3Aleancode.co&sort=downloads)

</div>
