require './lib/klient/version'

Gem::Specification.new do |s|
  s.name        = 'klient'
  s.version     = Klient::VERSION
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.description = "Experimental REST API client library."
  s.summary     = "Experimental REST API client library."
  s.authors     = ["John Fitisoff"]
  s.email       = 'jfitisoff@yahoo.com'

  s.required_ruby_version = ">=2.3.0"

  s.add_runtime_dependency "activesupport", [">=4.2.5"]
  s.add_runtime_dependency "addressable", [">=2.5.1"]
  s.add_runtime_dependency "nokogiri", [">=1.7.0"]
  # s.add_runtime_dependency "parsed_data"
  s.add_runtime_dependency "rest-client", [">=2.0.0"]

  s.add_development_dependency "coveralls", [">=0.8.21"]
  s.add_development_dependency "simplecov", [">=0.16.1"]
  s.add_development_dependency "pry", [">=0.11.3"]
  s.add_development_dependency "rake", [">=12.3.1"]
  s.add_development_dependency "rspec", [">=3.7.0"]

  s.files = [
    "lib/klient.rb",
    "lib/klient/hash_methods.rb",
    "lib/klient/klient.rb",
    "lib/klient/resource.rb",
    "lib/klient/resource_collection.rb",
    "lib/klient/resource_methods.rb",
    "lib/klient/response.rb",
    "lib/klient/response_data.rb",
    "lib/klient/version.rb"
  ]

  s.homepage    = 'https://github.com/jfitisoff/klient'
  s.license     = 'MIT'
end
