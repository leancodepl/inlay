/// Re-exports from the leancode_add2app framework package.
///
/// App-specific code in signal_module imports this file and gets access
/// to the framework's navigator API (including Flutter→native navigation).
library;

export 'package:leancode_add2app/leancode_add2app.dart'
    show Add2AppNavigator, Add2AppPage, PageBuilder, PageSettings;
