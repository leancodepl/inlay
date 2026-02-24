package co.leancode.add2app.example.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
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
import androidx.compose.ui.unit.dp
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import co.leancode.add2app.Add2AppFlutterScreen
import co.leancode.add2app.KeyValueStorageImpl
import co.leancode.example_module.generated.BadgeLevel
import co.leancode.example_module.generated.CounterPage
import co.leancode.example_module.generated.CounterStore
import co.leancode.example_module.generated.ProfilePage
import co.leancode.example_module.generated.UserBadge

class ComposeActivity : ComponentActivity() {
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
      }
    }

    composable("flutter-counter") {
      Add2AppFlutterScreen(
        route = CounterPage(seed = null),
        modifier = Modifier.fillMaxSize(),
      )
    }

    composable("flutter-profile/{userId}") { backStackEntry ->
      val userId = backStackEntry.arguments?.getString("userId") ?: "42"
      Add2AppFlutterScreen(
        route = ProfilePage(
          userId = userId,
          badges = listOf(UserBadge("Compose badge", BadgeLevel.silver)),
        ),
        modifier = Modifier.fillMaxSize(),
      )
    }

    composable("native-counter") {
      NativeCounterComposeScreen()
    }
  }
}

@Composable
private fun NativeCounterComposeScreen() {
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
      .padding(16.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp),
  ) {
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
