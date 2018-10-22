platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

target 'Hackers' do
  pod 'DZNEmptyDataSet'
  pod 'Eureka'
  pod 'FMDB'
  pod 'Kingfisher'
  pod 'libHN', :git => 'https://github.com/weiran/libHN'
  pod 'OpenGraph'
  pod 'PromiseKit', '~> 4.x'
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
