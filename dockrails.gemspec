$:.push File.expand_path("../lib", __FILE__)

require "dockrails/version"

Gem::Specification.new do |s|
  s.name                  = 'dockrails'
  s.version               = Dockrails::VERSION
  s.date                  = '2017-04-10'
  s.summary               = "Simple CLI to Generate and Run a Rails environment with Docker!"
  s.description           = "Docker + Rails + Mac + Dev = <3"
  s.homepage              = "https://github.com/gmontard/dockrails/"
  s.license               = "MIT"
  s.authors               = [ "Guillaume Montard" ]
  s.files                 = Dir["lib/**/*", "LICENSE", "README.me"]
  s.test_files            = Dir["spec/**/*"]
  s.required_ruby_version = ">= 2.0.0"
  s.executables           << 'dockrails'
  s.add_dependency 'commander', '~> 4.2'
  s.add_dependency 'docker-sync', '~> 0.2.3'

  s.add_development_dependency('rspec', '~> 3.2')
  s.add_development_dependency('rake')
  s.add_development_dependency('pry')
  s.add_development_dependency('fakefs')
  s.add_development_dependency('coveralls')
end
