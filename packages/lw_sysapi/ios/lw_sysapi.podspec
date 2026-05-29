Pod::Spec.new do |s|
  s.name             = 'lw_sysapi'
  s.version          = '0.0.1'
  s.summary          = 'System APIs for Linwood apps.'
  s.description      = 'Native system APIs for Linwood apps.'
  s.homepage         = 'https://linwood.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Linwood' => 'contact@linwood.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'
end
