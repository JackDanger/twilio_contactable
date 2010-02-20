require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'mocha'
require 'active_support'
require 'active_record'
require 'active_support/test_case'
require 'shoulda'
require File.join(File.dirname(__FILE__), "..", 'lib', 'four_info')

# default test configuration
FourInfo.configure do |config|
  config.client_id  = '1'
  config.client_key = 'ABCDEF'
end

FourInfo.mode = :test
config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3'])

ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.column :sms_phone_number,           :string
    t.column :sms_confirmed_phone_number, :string
    t.column :sms_blocked,                :boolean
    t.column :sms_confirmation_attempted, :datetime
    t.column :sms_confirmation_code,      :string

    t.column :type, :string
  end
end

class User < ActiveRecord::Base
  include FourInfo::Contactable
end

# kill all network access
module FourInfo
  class Request
    def start
      raise "You forgot to stub out your net requests!"
    end
  end
end
