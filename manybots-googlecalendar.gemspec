$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "manybots-googlecalendar/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "manybots-googlecalendar"
  s.version     = ManybotsGooglecalendar::VERSION
  s.authors     = ["Alexandre L. Solleiro"]
  s.email       = ["alex@webcracy.org"]
  s.homepage    = "https://www.manybots.com"
  s.summary     = "Add a Google Calendar Observer to your local Manybots"
  s.description = "Allows you to import events from Google Calendar into your local Manybots."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.1"
  s.add_dependency "oauth2"
  s.add_dependency "google-api-client", "~> 0.4.2"

  s.add_development_dependency "sqlite3"
end
