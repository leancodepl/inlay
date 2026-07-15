# inlay_compose example

Embedding inlay Flutter screens and dialogs in a Jetpack Compose host. For a
complete, runnable Compose host see
[`ComposeActivity.kt`](https://github.com/leancodepl/inlay/blob/main/example/example_android/app/src/main/java/co/leancode/inlay/example/android/ComposeActivity.kt)
in the example Android app.

Add the package next to `inlay` in your Flutter module's `pubspec.yaml`:

```yaml
dependencies:
  inlay: ^0.1.1
  inlay_compose: ^0.1.1
```

## Embed a Flutter screen as a Compose destination

```kotlin
import co.leancode.inlay.compose.InlayFlutterScreen

NavHost(navController, startDestination = "home") {
    composable("home") { HomeScreen() }

    composable("counter") {
        InlayFlutterScreen(
            route = CounterPage(seed = null),
            modifier = Modifier.fillMaxSize(),
            onResult = { count ->
                // count: Long? — the typed result the page popped with.
            },
        )
    }
}
```

## Show a Flutter dialog, state-driven

```kotlin
import co.leancode.inlay.compose.InlayFlutterDialog

var showDialog by remember { mutableStateOf(false) }

Button(onClick = { showDialog = true }) { Text("Delete") }

InlayFlutterDialog(
    isPresented = showDialog,
    route = ConfirmDeleteDialog(itemId = "42"),
    onDismissRequest = { showDialog = false },
    onResult = { confirmed ->
        // confirmed: Boolean? — already decoded.
    },
)
```

See the [navigation guide](https://github.com/leancodepl/inlay/blob/main/docs/navigation.md)
for the full Compose integration.
