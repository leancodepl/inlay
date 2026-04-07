package co.leancode.inlay.example.android

import android.app.Application
import co.leancode.inlay.InlayNavigator

class ExampleApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    InlayNavigator.init(this)
    InlayNavigator.setNativeRouteHandler(ExampleNativeRouteHandler)
  }
}
