
Pod::Spec.new do |s|


  s.name         = "GYFMDB"
  s.version      = "1.0.0"
  s.summary      = ""

  s.description  = "test"

  s.homepage     = "https://github.com/kenny2006cen/GYFMDB"

  s.license      = "MIT"


  s.author             = { "kenny2006cen" => "kenny2006cen@163.com" }
 
  s.summary      ="use of fmdb"
  s.platform     = :ios, "7.0"

  #  When using multiple platforms
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/kenny2006cen/GYFMDB.git", :tag => "1.0.0" }


  s.source_files  = "GYFMDB", "GYFMDB/**/GYFMDB.{h,m}"
  #s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"



   s.framework  = "UIKit"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"



  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "FMDB", "~> 2.6.2"

end
