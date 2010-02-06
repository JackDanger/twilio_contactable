require 'rubygems'
require 'active_support'
require 'active_support/test_case'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3'])


ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.column :phone,                      :string
    t.column :sms_confirmed,              :boolean
    t.column :sms_confirmation_attempted, :datetime
    t.column :sms_confirmation_code,      :string
  end
end


class User < ActiveRecord::Base
end

