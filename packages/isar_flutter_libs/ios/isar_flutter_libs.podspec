Pod::Spec.new do |s|
  s.name             = 'isar_flutter_libs'
  s.version          = '1.0.0'
  s.summary          = 'Flutter binaries for the Isar Database. Needs to be included for Flutter apps.'
  s.homepage         = 'https://isar.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Isar' => 'hello@isar.dev' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  s.vendored_libraries  = 'libisar.a'
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 arm64',
    'EXCLUDED_ARCHS[sdk=iphoneos*]' => 'armv7',
    'OTHER_LDFLAGS' => '-force_load $(PODS_TARGET_SRCROOT)/libisar.a'
  }
  s.user_target_xcconfig = { 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 arm64',
    'EXCLUDED_ARCHS[sdk=iphoneos*]' => 'armv7'
  }
  s.swift_version = '5.0'
end