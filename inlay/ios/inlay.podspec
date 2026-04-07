Pod::Spec.new do |s|
  s.name             = 'inlay'
  s.version          = '0.1.0'
  s.summary          = 'A cross-platform framework for embedding Flutter in native apps.'
  s.description      = <<-DESC
A cross-platform framework for embedding Flutter in native apps. Provides
navigation (push/pop via FlutterEngineGroup) and shared key-value storage
with real-time synchronization across multiple Flutter isolates and native code.
                       DESC
  s.homepage         = 'https://github.com/nicepage/inlay'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'LeanCode' => 'info@leancode.co' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
