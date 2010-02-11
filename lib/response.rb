module FourInfo
  class Response
    def initialize(xml)
      gem 'hpricot'
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
      self[:confcode].inner_text
    end
  end
end