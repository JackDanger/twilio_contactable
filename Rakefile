require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "twilio_contactable"
    gem.summary = %Q{Help authorize the users of your Rails apps to confirm and use their phone numbers}
    gem.description = %Q{Does all the hard work with letting you confirm your user's phone numbers for Voice or TXT over the Twilio API}
    gem.email = "gitcommit@6brand.com"
    gem.homepage = "http://github.com/JackDanger/twilio_contactable"
    gem.authors = ["Jack Danger Canty"]
    # gem.add_dependency "hpricot", ">= 0"
    # gem.add_dependency "haml", ">= 0"
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_development_dependency "mocha", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
desc "Test Twilio Contactable"
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
