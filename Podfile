platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

target 'Hackers' do
  pod 'ContextMenu'
  pod 'DZNEmptyDataSet'
  pod 'Eureka'
  pod 'FontAwesome.swift'
  pod 'HNScraper', :path => 'HNScraper'
  pod 'Kingfisher'
  pod 'OpenGraph'
  pod 'PromiseKit'
  pod 'RealmSwift'
  pod 'SkeletonView'
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
