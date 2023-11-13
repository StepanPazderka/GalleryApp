 platform :ios, '17.0'

target 'GalleryApp' do
  use_frameworks!

  # Pods for GalleryApp
  pod 'RxSwift'
  pod 'Realm'
  pod 'RealmSwift'
  pod 'RxDataSources'
  pod 'Swinject'
  pod 'DirectoryWatcher'
  pod 'SwiftLint'
  pod 'IQKeyboardManagerSwift'
  pod 'Lightbox'
end

# this settings sets up all pods deployment target
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'  # or whatever version you want
    end
  end
end

# ignore all warnings from all pods
inhibit_all_warnings!