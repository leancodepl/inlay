#!/bin/bash
# Generates pigeon code and patches Swift output with `public` access modifiers.
#
# Run from the leancode_add2app/ directory:
#   ./generate_pigeon.sh
#
set -euo pipefail
cd "$(dirname "$0")"

echo "Running pigeon for add2app_navigator..."
dart run pigeon --input pigeons/add2app_navigator.dart

echo "Running pigeon for key_value_storage..."
dart run pigeon --input pigeons/key_value_storage.dart

echo "Patching Swift files with public access modifiers..."

# --- Add2AppNavigatorApi.g.swift ---
NAV="ios/Classes/Add2AppNavigatorApi.g.swift"

# Error class
sed -i '' 's/^final class Add2AppNavigatorError/public final class Add2AppNavigatorError/' "$NAV"
sed -i '' '/class Add2AppNavigatorError/,/^}/ {
  s/^  let code/  public let code/
  s/^  let message/  public let message/
  s/^  let details/  public let details/
  s/^  init(/  public init(/
  s/^  var localizedDescription/  public var localizedDescription/
}' "$NAV"

# PageSettings struct
sed -i '' 's/^struct PageSettings: Hashable/public struct PageSettings: Hashable/' "$NAV"
sed -i '' '/struct PageSettings/,/^}/ {
  s/^  var routeId/  public var routeId/
  s/^  var params/  public var params/
  s/^  var path/  public var path/
  s/^  static func == /  public static func == /
  s/^  func hash(into/  public func hash(into/
}' "$NAV"

# Add public memberwise init for PageSettings (after the path property)
sed -i '' '/^  public var path: String? = nil$/a\
\
  public init(routeId: String, params: Any? = nil, path: String? = nil) {\
    self.routeId = routeId\
    self.params = params\
    self.path = path\
  }' "$NAV"

# --- KeyValueStorageApi.g.swift ---
KVS="ios/Classes/KeyValueStorageApi.g.swift"

# StorageEntry struct
sed -i '' 's/^struct StorageEntry: Hashable/public struct StorageEntry: Hashable/' "$KVS"
sed -i '' '/struct StorageEntry/,/^}/ {
  s/^  var key/  public var key/
  s/^  var value/  public var value/
  s/^  static func == /  public static func == /
  s/^  func hash(into/  public func hash(into/
}' "$KVS"

# Add public memberwise init for StorageEntry (after the value property)
sed -i '' '/^  public var value: String$/a\
\
  public init(key: String, value: String) {\
    self.key = key\
    self.value = value\
  }' "$KVS"

echo "Done."
