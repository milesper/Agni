# Uncomment the next line to define a global platform for your project
 platform :ios, '11.0'

target 'Agni' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Agni
	pod 'Firebase/Core'
	pod 'Firebase/Firestore'
	pod 'Firebase/Storage'
	pod 'iCarousel'

  target 'AgniTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'Agni Stickers' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Agni Stickers

end

target 'OneSignalNotificationServiceExtension' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for OneSignalNotificationServiceExtension

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
        end
    end
end
