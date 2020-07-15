Pod::Spec.new do |s|
  s.name             = 'ZLYQAnalyticSDK'
  s.version          = '0.1.6'
  s.summary          = 'Upload events.'
  s.description      = <<-DESC
  'Upload all custom events and default events.'
                       DESC
  s.homepage         = 'https://github.com/zlzz-rec/zlyq-ios-sdk.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhangyanming' => 'zhangyanming0163@163.com' }
  s.source           = { :git => 'https://github.com/zlzz-rec/zlyq-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  
  s.default_subspec = 'Framework'
  
  s.subspec 'Framework' do |f|
    f.vendored_frameworks = ['Products/**/*.framework']
  end
  
  s.subspec 'Code' do |f|
    f.source_files = "ZLYQAnalyticSDK/**/*.{h,m}"
  end
    
  s.dependency 'AFNetworking'
end

