package co.leancode.add2app.example.android

import android.app.Application
import co.leancode.add2app.Add2AppNavigator

class ExampleApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    Add2AppNavigator.init(this)
    Add2AppNavigator.setNativeRouteHandler(ExampleNativeRouteHandler)
  }
}
