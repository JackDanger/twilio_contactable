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

  Gateway = URI.parse 'http://gateway.4info.net:8080/msg'

  module Contactable

    Attributes = [  :sms_phone_number,
                    :sms_confirmation_code,
                    :sms_confirmation_attempted,
                    :sms_confirmed ]

    def self.included(model)
      gem 'haml'
      require 'haml'
      require 'net/http'

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
        # provide a helper method to access the right value
        # no matter which column it's stored in
        #
        # e.g.: @user.four_info_sms_confirmed
        #       => @user.send(User.sms_confirmed_column)
        model.class_eval "
          def four_info_#{attribute}(value = nil)
            value ?
              send(self.class.#{attribute}_column.to_s+'=', value) :
              send(self.class.#{attribute}_column)
          end
          alias_method :four_info_#{attribute}?, :four_info_#{attribute}
          alias_method :four_info_#{attribute}=, :four_info_#{attribute}
        "
      end
    end

    def confirm_sms!
      Confirmation.new(four_info_sms_phone_number, self).try
    end
  end

  class Confirmation
    def initialize(number, contactable_record)
      @number = FourInfo.numerize(number)
      @contactable_record = contactable_record
    end

    def try
      return true  if @contactable_record.four_info_sms_confirmed?
      return false if @number.blank?

      response = Request.new.confirm(@number)
      if response.success?
        @contactable_record.four_info_sms_confirmation_code = response.confirmation_code
        @contactable_record.four_info_sms_confirmation_attempted = Time.now
        @contactable_record.save
        true
      else
        # "Confirmation Failed: #{response.inspect}"
        false
      end
    end
  end

  class Request

    # Haml templates for XML
    @@templates = Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), 'templates', '*.haml')))

    # YML config files
    @@test_mode_config_file = File.join(File.dirname(__FILE__), '..', 'test', 'sms.yml')
    @@likely_config_files = [
        File.join(File.dirname(__FILE__), '..', 'sms.yml'),
        defined?(Rails) ? File.join(Rails.root, 'config', 'sms.yml') : '',
        File.join('config', 'sms.yml'),
        'sms.yml'
    ]

    attr_accessor :config
    attr_accessor :number

    def initialize
      config_file = :test == FourInfo.mode ?
                      @@test_mode_config_file :
                      @@likely_config_files.detect {|f| File.exist?(f) }

      raise "Missing config File! Please add sms.yml to ./config or the 4info directory" unless config_file

      @config = YAML.load(File.read(config_file))['4info'].with_indifferent_access
    end

    def confirm(number)
      self.number = FourInfo.internationalize(number)

      xml = template(:confirm).render(self)
      Response.new(perform(xml))
    end

    def template(name)
      file = @@templates.detect {|t| File.basename(t).chomp('.haml').to_sym == name.to_sym }
      raise ArgumentError, "Missing 4Info template: #{name}" unless file
      Haml::Engine.new(File.read(file))
    end

    class Response
      def initialize(xml)
        require 'hpricot'
        @body = Hpricot.parse(xml)
      end

      def [](name)
        nodes = (@body/name)
        1 == nodes.size ? nodes.first : nodes
      end

      def success?
        'Success' == self['message'].inner_text
      end

      def confirmation_code
        self['confCode'].inner_text
      end
    end

    protected

      def perform(body)
        STDOUT.puts('in perform')
        start do |http|
          http.post(Gateway.path, body).read_body
        end
      end

      def start
        net = config[:proxy].blank? ?
                Net::HTTP :
                Net::HTTP::Proxy(*config[:proxy].split(":"))
        net.start(Gateway.host, Gateway.port) do |http|
          yield http
        end
      end
  end
end