package co.leancode.inlay.example.android

import android.app.Application
import co.leancode.example_module.generated.InlaySchema
import co.leancode.inlay.InlayNavigator

class ExampleApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    // Lets Flutter engines detect a module built from a different schema
    // revision than this host.
    InlayNavigator.setSchemaFingerprint(InlaySchema.FINGERPRINT)
    InlayNavigator.init(this)
    InlayNavigator.setNativeRouteHandler(ExampleNativeRouteHandler)
  }
}
