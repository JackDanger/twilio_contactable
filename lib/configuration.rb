module FourInfo
  class << self
    def mode
      @@mode ||= :test
    end

    def mode=(new_mode)
      @@mode = new_mode
    end

    def configured?
      return false unless configuration
      configuration.client_id && configuration.client_key
    end

    def configuration
      @@configuration
    end

    def configure(&block)
      @@configuration = Configuration.new(&block)
    end
  end

  class Configuration

    attr_accessor :client_id
    attr_accessor :client_key
    attr_accessor :short_code
    attr_accessor :proxy_address
    attr_accessor :proxy_port
    attr_accessor :proxy_username
    attr_accessor :proxy_password

    def initialize
      yield self
    end
  end
end