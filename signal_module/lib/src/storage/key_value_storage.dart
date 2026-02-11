/// Re-exports from the leancode_add2app framework package.
///
/// App-specific code in signal_module imports this file and gets access
/// to the framework's key-value storage API.
library;

export 'package:leancode_add2app/leancode_add2app.dart'
    show KeyValueStorage, StorageEntry;
