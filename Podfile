# Uncomment this line to define a global platform for your project
platform :ios, '12.0'
# Uncomment this line if you're using Swift
use_frameworks!

target 'Ketchup' do
  
  # 글씨
  pod 'FontBlaster'
  
  # Image, Gif (움짤, 사진)
  pod 'CropViewController'
  pod 'lottie-ios', '4.0.1'
  
  # data BackUp/DB
  pod 'GoogleSignIn'#, '6.0.0'
  pod 'GoogleAPIClientForREST/Drive', '~> 1.3.7'
  pod 'Firebase/Core', '10.1.0'
  pod 'Firebase/Auth', '10.1.0'
  pod 'Firebase/Crashlytics', '10.1.0'
  pod 'Firebase/Analytics', '10.1.0'
  pod 'RealmSwift'
  
  pod 'Toast-Swift' ,'~> 5.0.0'
  
  #RxXXXX
  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'RxDataSources', '~> 4.0'
  pod 'RxKingfisher'
  pod 'SwiftyJSON', '5.0.0'
  
  post_install do |installer|
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
        end
      end
end
