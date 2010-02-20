module FourInfo
  class << self
    def gateway
      require 'net/http'
      URI.parse 'http://gateway.4info.net/msg'
    end

    def log(msg)
      if defined?(Rails)
        Rails.logger.info msg
      else
        STDOUT.puts msg
      end
    end

    def numerize(numberish)
      numberish.to_s.scan(/\d+/).join
    end

    def internationalize(given_number)
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

    def confirmation_message(confirmation_code)
      "4INFO alert confirm. code: #{confirmation_code} Enter code on web to verify phone. Msg&data rates may apply. Freq set by u. T&C & support at www.4info.com. Txt HELP for help"
    end
  end
end

require File.join(File.dirname(__FILE__), 'configuration')
require File.join(File.dirname(__FILE__), 'contactable')
require File.join(File.dirname(__FILE__), 'controller')
require File.join(File.dirname(__FILE__), 'request')
require File.join(File.dirname(__FILE__), 'response')
