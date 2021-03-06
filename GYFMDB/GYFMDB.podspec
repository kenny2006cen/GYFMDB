
Pod::Spec.new do |s|


  s.name         = "GYFMDB"
  s.version      = "1.0.2"
  s.summary      = "use of fmdb"

  s.description  = "clever use of the fmdb "

  s.homepage     = "https://github.com/kenny2006cen/GYFMDB"

  s.license      = "MIT"


  s.author             = { "kenny2006cen" => "kenny2006cen@163.com" }
 
  
  s.platform     = :ios, "9.0"

  #  When using multiple platforms
  s.ios.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/kenny2006cen/GYFMDB.git", :tag => "#{s.version}" }


  s.source_files  = "GYFMDB", "GYFMDB/**/*GY*.{h,m}"
  #s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"



   s.framework  = "UIKit"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"



  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
   s.dependency "FMDB", "~> 2.6.2"

end
