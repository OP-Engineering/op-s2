require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "op-s2"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "12.0" }
  s.source       = { :git => "https://github.com/OP-Engineering/op-s2.git", :tag => "#{s.version}" }

  s.header_mappings_dir = "cpp"
  s.source_files = "ios/**/*.{h,m,mm}", "cpp/**/*.{c,h,hpp,cpp}"
  s.framework = "LocalAuthentication"

  install_modules_dependencies(s)
end
