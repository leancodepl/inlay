Pod::Spec.new do |s|
  s.name             = 'example_module_native'
  s.version          = '0.1.0'
  s.summary          = 'Companion plugin for example_module — holds generated native code.'
  s.description      = <<-DESC
Companion plugin for example_module. Holds generated native code (Routes, Stores)
so that flutter build aar bundles them into binary artifacts.
                       DESC
  s.homepage         = 'https://github.com/nicepage/inlay'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'LeanCode' => 'info@leancode.co' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'inlay'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
