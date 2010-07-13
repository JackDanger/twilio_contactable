module Txter
  class Gateway
    class Request
    end

    class Response
      def initialize(*args)
        @options = args.last
      end

      def success?
        :success == @options[:status]
      end
    end
    Success = Txter::Gateway::Response.new(:status => :success)
    Error   = Txter::Gateway::Response.new(:status => :error)

    def self.deliver(*args)
      # subclasses should actually do something here
      Success 
    end

    def self.unblock(*args)
      # subclasses should actually do something here
      Success 
    end

    def self.current
      case Txter.configuration.gateway
      when 'twilio'
        gem 'twiliolib'
        require 'twiliolib'
        GatewayTwilio
      when '4info'
        Gateway4info
      when 'test'
        Txter::Gateway
      else
        raise "You need to specify your Txter gateway!"
      end
    end
  end
end
require File.join(File.dirname(__FILE__), 'gateway_4info')
require File.join(File.dirname(__FILE__), 'gateway_twilio')
