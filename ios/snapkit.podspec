#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint snapkit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'snapkit'
  s.version          = '1.0.0'
  s.summary          = 'Snapchat\'s SnapKit for Flutter'
  s.description      = <<-DESC
  A Flutter Plugin for integrating with Snapchat\'s SnapKit on iOS & Android
                       DESC
  s.homepage         = 'https://github.com/TimmyRB/Flutter-SnapKit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jacob Brasil' => 'jnxtbrasil@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'SnapSDK', '1.11.0'
  s.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
