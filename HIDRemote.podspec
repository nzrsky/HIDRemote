
Pod::Spec.new do |s|
  s.name         = 'HIDRemote'
  s.version      = '1.8.0'
  s.summary      = 'Access the Apple IR Receiver / Apple Remote'
  s.homepage     = 'https://github.com/nzrsky/HIDRemote'
  s.license      = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author       = { 'Felix Schwarz' => 'https://github.com/felix-schwarz', 'Alexey Nazarov' => 'alexx.nazaroff@gmail.com' }
  s.source       = { :git => 'https://github.com/nzrsky/HIDRemote.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nzrsky'

  s.osx.deployment_target = '10.10'

  s.requires_arc = true
  s.frameworks = 'Foundation', 'IOKit', 'Cocoa'
  s.source_files = 'HIDRemote/**/*.{h,m}'
end

