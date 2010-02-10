require File.join(File.dirname(__FILE__), 'contactable')
require File.join(File.dirname(__FILE__), 'request')
require File.join(File.dirname(__FILE__), 'response')

module FourInfo
  Gateway = URI.parse 'http://gateway.4info.net/msg'

  class << self
    def mode
      @@mode ||= :live
    end
    def mode=(new_mode)
      @@mode = new_mode
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
  end
end