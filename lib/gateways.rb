module Txter
  class Gateway

    def self.current
      case Txter.configuration.gateway
      when 'twilio'
        GatewayTwilio
      when '4info'
        Gateway4info
    end

  end
end
require 'gateway_4info'
require 'gateway_twilio'
