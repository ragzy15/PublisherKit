Pod::Spec.new do |spec|

  spec.name             = "PublisherKit"
  spec.version          = "4.0.1"
  spec.summary          = "An open source implementation of Apple's Combine framework for processing asynchronous events over time"

  spec.homepage         = "https://github.com/ragzy15/PublisherKit"
  spec.license          = "MIT"

  spec.author           = { "Raghav Ahuja" => "raghavahuja@icloud.com" }
  spec.source           = { :git => "https://github.com/ragzy15/PublisherKit.git", :tag => "#{spec.version}" }
  
  spec.social_media_url = "https://twitter.com/ahujaraghav1"
  
  spec.swift_version    = "5.0"

  spec.ios.deployment_target        = "8.0"
  spec.osx.deployment_target        = "10.10"
  spec.tvos.deployment_target       = "9.0"
  spec.watchos.deployment_target    = "3.0"
  
  spec.source_files        = "Sources/PublisherKitHelpers/**/*.{h,cpp}", "Sources/PublisherKit/**/*.swift"
  spec.public_header_files = "Sources/PublisherKitHelpers/include/*.h"
  
  spec.libraries = "c++"

end
