# Uncomment the next line to define a global platform for your project
platform :ios, '17.2'

target 'Today-s-Meal' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Today-s-Meal
  pod 'GoogleMaps', '8.0.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
  
  installer.aggregate_targets.each do |target|
    target.xcconfigs.each do |variant, xcconfig|
      xcconfig_path = target.client_root + target.xcconfig_relative_path(variant)
      IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("USE_RECURSIVE_SCRIPT_INPUTS_IN_SCRIPT_PHASES = YES", "USE_RECURSIVE_SCRIPT_INPUTS_IN_SCRIPT_PHASES = YES\nENABLE_USER_SCRIPT_SANDBOXING = NO"))
    end
  end
end 