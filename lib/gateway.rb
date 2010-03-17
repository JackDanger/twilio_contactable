module Txter
  class Gateway

    def self.deliver(*args)
      Response.new(:status => :success)
    end

    def self.unblock(*args)
      Response.new(:status => :success)
    end

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

    def self.current
      case Txter.configuration.gateway
      when 'twilio'
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
require 'gateway_4info'
require 'gateway_twilio'
