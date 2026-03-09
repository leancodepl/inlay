Pod::Spec.new do |s|
  s.name             = 'leancode_add2app'
  s.version          = '0.1.0'
  s.summary          = 'A cross-platform add2app framework for Flutter.'
  s.description      = <<-DESC
A cross-platform add2app framework for Flutter. Provides navigation
(push/pop via FlutterEngineGroup) and shared key-value storage with
real-time synchronization across multiple Flutter isolates and native code.
                       DESC
  s.homepage         = 'https://github.com/nicepage/leancode_add2app'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'LeanCode' => 'info@leancode.co' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
