require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))
folly_compiler_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32'

Pod::Spec.new do |s|
  s.name         = "op-engineering-op-secure-storage"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "12.0" }
  s.source       = { :git => "https://github.com/OP-Engineering/op-secure-storage.git", :tag => "#{s.version}" }

  s.pod_target_xcconfig = {
    :WARNING_CFLAGS => "-Wno-shorten-64-to-32 -Wno-comma -Wno-unreachable-code -Wno-conditional-uninitialized -Wno-deprecated-declarations",
    :USE_HEADERMAP => "No"
  }

  s.header_mappings_dir = "cpp"
  s.source_files = "ios/**/*.{h,m,mm}"
  
  s.dependency "React"
  s.dependency "React-Core"
  s.dependency "React-callinvoker"
  s.framework = "LocalAuthentication"   
end
