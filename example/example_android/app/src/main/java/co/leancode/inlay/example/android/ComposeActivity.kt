package co.leancode.inlay.example.android

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.ui.unit.dp
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.dialog
import androidx.navigation.compose.rememberNavController
import co.leancode.inlay.InlayFlutterDialogScreen
import co.leancode.inlay.InlayFlutterScreen
import co.leancode.inlay.KeyValueStorageImpl
import co.leancode.example_module.generated.BadgeLevel
import co.leancode.example_module.generated.ConfirmActionDialog
import co.leancode.example_module.generated.CounterPage
import co.leancode.example_module.generated.CounterStore
import co.leancode.example_module.generated.ProfilePage
import co.leancode.example_module.generated.UserBadge

class ComposeActivity : AppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContent {
      MaterialTheme {
        ComposeHost()
      }
    }
  }
}

@Composable
private fun ComposeHost() {
  val navController = rememberNavController()
  NavHost(navController = navController, startDestination = "home") {
    composable("home") {
      Column(
        modifier = Modifier
          .fillMaxSize()
          .statusBarsPadding()
          .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
      ) {
        Text("Compose + Flutter integration")
        Button(onClick = { navController.navigate("flutter-counter") }) {
          Text("Open Flutter Counter")
        }
        Button(onClick = { navController.navigate("flutter-profile/42") }) {
          Text("Open Flutter Profile")
        }
        Button(onClick = { navController.navigate("native-counter") }) {
          Text("Open native Compose Counter")
        }
        Button(onClick = { navController.navigate("confirm-dialog/delete") }) {
          Text("Open Confirm Dialog")
        }
      }
    }

    composable("flutter-counter") {
      InlayFlutterScreen(
        route = CounterPage(seed = null),
        modifier = Modifier
          .fillMaxSize()
          .statusBarsPadding(),
      )
    }

    composable("flutter-profile/{userId}") { backStackEntry ->
      val userId = backStackEntry.arguments?.getString("userId") ?: "42"
      InlayFlutterScreen(
        route = ProfilePage(
          userId = userId,
          badges = listOf(UserBadge("Compose badge", BadgeLevel.silver)),
        ),
        modifier = Modifier
          .fillMaxSize()
          .statusBarsPadding(),
      )
    }

    dialog("confirm-dialog/{action}") { backStackEntry ->
      val action = backStackEntry.arguments?.getString("action") ?: "delete"
      InlayFlutterDialogScreen(
        route = ConfirmActionDialog(action = action, message = "Are you sure?"),
        modifier = Modifier.fillMaxSize(),
      )
    }

    composable("native-counter") {
      NativeCounterComposeScreen(
        onBack = { navController.popBackStack() },
      )
    }
  }
}

@Composable
private fun NativeCounterComposeScreen(onBack: () -> Unit) {
  val storage = remember { KeyValueStorageImpl.createScope() }
  val store = remember { CounterStore(storage) }

  var count by remember { mutableLongStateOf(store.count) }
  var updatedBy by remember { mutableStateOf(store.lastUpdatedBy) }

  DisposableEffect(Unit) {
    storage.startObserving {
      count = store.count
      updatedBy = store.lastUpdatedBy
    }
    onDispose {
      storage.dispose()
    }
  }

  Column(
    modifier = Modifier
      .fillMaxSize()
      .statusBarsPadding()
      .padding(16.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp),
  ) {
    Button(onClick = onBack) {
      Text("Back")
    }
    Text("Native Compose Counter")
    Text("Count: $count")
    Text("Last updated by: $updatedBy")
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
      Button(onClick = {
        store.count = store.count + 1
        store.lastUpdatedBy = "android-compose"
        count = store.count
        updatedBy = store.lastUpdatedBy
      }) {
        Text("+")
      }
      Button(onClick = {
        store.count = store.count - 1
        store.lastUpdatedBy = "android-compose"
        count = store.count
        updatedBy = store.lastUpdatedBy
      }) {
        Text("-")
      }
    }
  }
}
