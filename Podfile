platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

target 'Hackers' do
  pod '1PasswordExtension'
  pod 'Alamofire'
  pod 'CodableFirebase'
  pod 'ContextMenu'
  pod 'DZNEmptyDataSet'
  pod 'Eureka'
  pod 'Firebase/Database'
  pod 'FontAwesome.swift'
  pod 'HNScraper', :path => 'HNScraper'
  pod 'Kingfisher'
  pod 'ObjectMapper'
  pod 'ObjectMapperAdditions/Realm'
  pod 'OpenGraph', :git => 'https://github.com/robbiet480/OpenGraph', :branch => 'patch-1'
  pod 'PromiseKit'
  pod 'PromiseKit/Alamofire'
  pod 'RealmSwift'
  pod 'SkeletonView'
  pod 'SwiftDate'
  pod 'SwiftSoup'
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
