

module FourInfo
  module Contactable

    # The contactable record should have the following columns:
    #   phone (string, integer)
    #   sms_confirmed (boolean)
    #   sms_confirmation_attempted (datetime)
    #   sms_confirmation_code (string)

    def confirm_sms!
      Confirmation.new(phone, self).try
    end
  end

  class Confirmation
    def initialize(number, contactable_record)
      @number = number
      @contactable_record = contactable_record
    end

    def try
      return true if @contactable_record.sms_confirmed?

      response = Request.confirm(@number)
      if response.success?
        @contactable_record.sms_confirmation_code = response.confirmation_code
        @contactable_record.sms_confirmation_attempted = Time.now
        @contactable_record.save
      else
    end
  end

  def Request
    extend self

    Templates = Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), 'templates', '*.haml')))

    config_file = [
      File.join(File.dirname(__FILE__), '..', 'sms.yml'),
      defined?(Rails) ? File.join(Rails.root, 'config', 'sms.yml') : '',
      File.join('config', 'sms.yml'),
      'sms.yml',
    ].detect {|f| File.exist?(f) }

    raise "Missing Config File! Please add sms.yml to ./config or the 4info directory"

    Config = YAML.load(ERB.new(File.read(config_file)).render)['4info']

    def confirm(number)
      xml = template(:confirm).render(Config.merge(:number => format_number(number)))
      puts xml
      put(xml)
    end

    def template(name)
      file = Templates.detect {|t| File.basename(t).chomp('.haml') == name}
      raise ArgumentError, "Missing 4Info template: #{name}" unless file
      Haml::Engine.new(File.read(file))
    end

    def format_number(number)
      case number.size
      when 10
        "+1#{number}"
      when 11
        "+#{number}"
      when 12
        number.to_s
      else
        raise ArgumentError, "Number is not a valid 10-digit number: #{number.inspect}"
      end
    end
  end
end