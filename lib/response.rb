module Txter
  class Response
    def initialize(xml)
      p xml
      gem 'hpricot'
      require 'hpricot'
      @xml  = xml
      @body = Hpricot.parse(xml)
    end

    def inspect
      @xml.to_s
    end

    def [](name)
      nodes = (@body/name)
      1 == nodes.size ? nodes.first : nodes
    end

    def success?
      'Success' == self['message'].inner_text
    end

    def confirmation_code
      self[:confcode].inner_text
    end
  end
end