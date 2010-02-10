require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "4info"
    gem.summary = %Q{Send and receive SMS messages via 4info.com}
    gem.description = %Q{A complete Ruby API for handling SMS messages via 4info.com}
    gem.email = "gitcommit@6brand.com"
    gem.homepage = "http://github.com/JackDanger/4info"
    gem.authors = ["Jack Danger Canty"]
    gem.add_dependency "hpricot", ">= 0"
    gem.add_dependency "haml", ">= 0"
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_development_dependency "mocha", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
desc "Test 4info"
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "inline_styles #{version}"
  rdoc.rdoc_files.include('lib/**/*.rb')
end
