#
# Be sure to run `pod lib lint AutoBindObject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AutoBindObject'
  s.version          = '0.1.0'
  s.summary          = 'Bind NSDictionary to Custom Object automatically. Generate NSDictionary from object properties.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.homepage         = 'https://github.com/caohuuloc/AutoBindObject'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Cao Huu Loc' => 'caohuuloc@yahoo.com' }
  s.source           = { :git => 'https://github.com/caohuuloc/AutoBindObject.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://www.facebook.com/caohuuloc'

  s.ios.deployment_target = '8.0'

  s.source_files = 'AutoBindObject/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AutoBindObject' => ['AutoBindObject/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
