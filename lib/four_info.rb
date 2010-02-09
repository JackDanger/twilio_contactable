gem 'haml'
require 'haml'

module FourInfo
  def self.mode;     @@mode ||= :live; end
  def self.mode=(m); @@mode = m;      end

  def self.numerize(numberish)
    numberish.to_s.scan(/\d+/).join
  end

  def self.internationalize(given_number)
    number = numerize(given_number)
    case number.size
    when 10
      "+1#{number}"
    when 11
      "+#{number}"
    when 12
      number =~ /\+\d(11)/ ? number : nil
    else
      nil
    end
  end

  module Contactable

    Attributes = [  :sms_phone_number,
                    :sms_confirmation_code,
                    :sms_confirmation_attempted,
                    :sms_confirmed ]

    def self.included(model)
      Attributes.each do |attribute|
        # add a method for setting or retrieving
        # which column should be used for which attribute
        # 
        # :sms_phone_number_column defaults to :sms_phone_number, etc.
        model.instance_eval "
          def #{attribute}_column(value = nil)
            @#{attribute}_column ||= :#{attribute}
            @#{attribute}_column = value if value
            @#{attribute}_column
          end
        "
      end
    end

    def confirm_sms!
      Confirmation.new(phone, self).try
    end
  end

  class Confirmation
    def initialize(number, contactable_record)
      @number = FourInfo.numerize(number)
      @contactable_record = contactable_record
    end

    def try
      return true  if @contactable_record.sms_confirmed?
      return false if @number.blank?

      response = Request.new.confirm(@number)
      if response.success?
        @contactable_record.sms_confirmation_code = response.confirmation_code
        @contactable_record.sms_confirmation_attempted = Time.now
        @contactable_record.save
      else
        raise "Confirmation Failed: #{response.inspect}"
      end
    end
  end

  class Request

    @@templates = Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), 'templates', '*.haml')))
    @@test_mode_config_file = File.join(File.dirname(__FILE__), '..', 'test', 'sms.yml')
    @@likely_config_files = [
        File.join(File.dirname(__FILE__), '..', 'sms.yml'),
        defined?(Rails) ? File.join(Rails.root, 'config', 'sms.yml') : '',
        File.join('config', 'sms.yml'),
        'sms.yml'
    ]

    def initialize
      config_file = :test == FourInfo.mode ?
                      @@test_mode_config_file :
                      @@likely_config_files.detect {|f| File.exist?(f) }

      raise "Missing config File! Please add sms.yml to ./config or the 4info directory" unless config_file

      @config = YAML.load(File.read(config_file))['4info']
    end

    def confirm(number)
      xml = template(:confirm).render(@config.merge(:number => FourInfo.internationalize(number)))
      puts xml
      put(xml)
    end

    def template(name)
      file = @@templates.detect {|t| File.basename(t).chomp('.haml').to_sym == name.to_sym }
      raise ArgumentError, "Missing 4Info template: #{name}" unless file
      Haml::Engine.new(File.read(file))
    end
  end
end