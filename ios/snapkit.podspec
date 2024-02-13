#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint snapkit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'snapkit'
  s.version          = '3.0.0'
  s.summary          = 'Flutter plugin for integrating with Snapchat.'
  s.description      = <<-DESC
Flutter plugin for integrating with Snapchat.
                       DESC
  s.homepage         = 'http://jacobbrasil.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jacob Brasil' => 'hello@jacobbrasil.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.dependency 'SnapSDK', '~> 2.5.0'
end
