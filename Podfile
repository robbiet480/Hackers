platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

target 'Hackers' do
  pod 'DZNEmptyDataSet'
  pod 'Eureka'
  pod 'Kingfisher'
  #pod 'libHN', :git => 'https://github.com/weiran/libHN', :commit => '6759f4ac591f5f36b01158260627ba0bf36eddc1'
  pod 'HNScraper', :git => 'https://github.com/tsucres/HNScraper'
  pod 'OpenGraph'
  pod 'PromiseKit'
  pod 'RealmSwift'
  pod 'SkeletonView'
  pod 'ContextMenu'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if ['PromiseKit', 'SkeletonView'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
      end
    end
  end
end
