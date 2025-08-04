Pod::Spec.new do |s|
  s.name             = 'BenefitPay-iOS'
  s.version          = '1.0.1'
  s.summary          = 'From the shelf pay with benefit pay button by Tap Payments'
  s.homepage         = 'https://github.com/Tap-Payments/BenefitPay-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'o.rabie' => 'o.rabie@tap.company', 'h.sheshtawy' => 'h.sheshtawy@tap.company' }
  s.source           = { :git => 'https://github.com/Tap-Payments/BenefitPay-iOS.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/BenefitPay-iOS/Logic/**/*.swift'
  s.resources = "Sources/BenefitPay-iOS/Resources/**/*.{json,xib,pdf,png,gif,storyboard,xcassets,xcdatamodeld,lproj}"
  s.dependency'SwiftyRSA'
  s.dependency'SharedDataModels-iOS'
  s.dependency'TapFontKit-iOS'
  s.dependency'Robin'
  
  
end
