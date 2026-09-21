Pod::Spec.new do |s|
  s.name             = 'inlay'
  s.version          = '0.2.0'
  s.summary          = 'Embed Flutter in native iOS and Android apps with type-safe navigation and storage.'
  s.description      = <<-DESC
Embed Flutter in native iOS and Android apps with type-safe navigation and
key-value storage synced in real time across engines and native code.
                       DESC
  s.homepage         = 'https://github.com/leancodepl/inlay'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'LeanCode' => 'info@leancode.co' }
  s.source           = { :path => '.' }
  s.source_files     = 'inlay/Sources/inlay/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
