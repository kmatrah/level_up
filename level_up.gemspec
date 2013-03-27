$:.push File.expand_path("../lib", __FILE__)

require "level_up/version"

Gem::Specification.new do |s|
  s.name        = "level_up"
  s.version     = LevelUp::VERSION
  s.authors     = ["Karim Matrah"]
  s.email       = ["karim.matrah@gmail.com"]
  s.homepage    = "https://github.com/kmatrah/level_up"
  s.summary     = "A rails engine to structure, run and manage asynchronous jobs"
  s.description = "A rails engine to structure, run and manage asynchronous jobs"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE.txt", "Rakefile", "README.md", "CHANGELOG.txt"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2"
  s.add_dependency "jquery-rails"
  s.add_dependency "sass-rails"
  s.add_dependency "meta_search"
  s.add_dependency "kaminari"
  s.add_dependency "ruby-graphviz"
  s.add_dependency "delayed_job", "~> 3.0"
  s.add_dependency "delayed_job_active_record", "~> 0.3"

  s.add_development_dependency  "rake"
  s.add_development_dependency "sqlite3"
end
