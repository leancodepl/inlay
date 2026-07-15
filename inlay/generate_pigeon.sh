#!/bin/bash
# Generates pigeon code and patches Swift output with `public` access modifiers.
#
# Run from the inlay/ directory:
#   ./generate_pigeon.sh
#
set -euo pipefail
cd "$(dirname "$0")"

echo "Running pigeon for inlay_navigator..."
dart run pigeon --input pigeons/inlay_navigator.dart

echo "Running pigeon for key_value_storage..."
dart run pigeon --input pigeons/key_value_storage.dart

echo "Patching Swift files with public access modifiers..."

# --- InlayNavigatorApi.g.swift ---
NAV="ios/inlay/Sources/inlay/InlayNavigatorApi.g.swift"

# Error class
sed -i '' 's/^final class InlayNavigatorError/public final class InlayNavigatorError/' "$NAV"
sed -i '' '/class InlayNavigatorError/,/^}/ {
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
  s/^  var schemaFingerprint/  public var schemaFingerprint/
  s/^  static func == /  public static func == /
  s/^  func hash(into/  public func hash(into/
}' "$NAV"

# Add public memberwise init for PageSettings (after the last property)
sed -i '' '/^  public var schemaFingerprint: String? = nil$/a\
\
  public init(routeId: String, params: Any? = nil, path: String? = nil, schemaFingerprint: String? = nil) {\
    self.routeId = routeId\
    self.params = params\
    self.path = path\
    self.schemaFingerprint = schemaFingerprint\
  }' "$NAV"

# --- KeyValueStorageApi.g.swift ---
KVS="ios/inlay/Sources/inlay/KeyValueStorageApi.g.swift"

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
