#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint firebase_messaging_handler.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'firebase_messaging_handler'
  s.version          = '1.0.0'
  s.summary          = 'A comprehensive Flutter plugin for handling Firebase Cloud Messaging notifications with advanced features.'
  s.description      = <<-DESC
A comprehensive Flutter plugin for handling Firebase Cloud Messaging notifications with advanced features.
                       DESC
  s.homepage         = 'https://github.com/neel-sharma/firebase_messaging_handler'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Qoder' => 'neel@qoder.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/Messaging'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
