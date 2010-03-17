module Txter
  class Gateway4info < Txter::Gateway

    def self.deliver(message, number)
      Request.new.deliver_message(message, number)
    end

    class Response < Txter::Gateway::Response
      def initialize(xml)
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

    class Request < Txter::Gateway::Request

      attr_accessor :number
      attr_accessor :message

      def initialize
        unless Txter.configured?
          raise "You need to configure Txter before using it!"
        end
        self.config = Txter.configuration
      end

      def deliver_message(message, number)
        self.number  = Txter.internationalize(number)
        self.message = message

        xml = template(:deliver).render(self)
        Response.new(perform(xml))
      end

      def confirm(number)
        self.number  = Txter.internationalize(number)

        xml = template(:confirm).render(self)
        Response.new(perform(xml))
      end

      def unblock(number)
        self.number = Txter.internationalize(number)

        xml = template(:unblock).render(self)
        Response.new(perform(xml))
      end

      protected

        def template(name)
          # Haml templates for XML
          require 'cgi'
          templates = Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), 'templates', '*.haml')))
          file = templates.detect {|t| File.basename(t).chomp('.haml').to_sym == name.to_sym }
          raise ArgumentError, "Missing 4Info template: #{name}" unless file
          Haml::Engine.new(File.read(file))
        end
    end

    protected

      def perform(body)
        if :live == Txter.mode
          require 'net/http'
          uri = URI.parse 'http://gateway.4info.net/msg'
          start do |http|
            http.post(
                       uri.path,
                       body,
                       {'Content-Type' => 'text/xml'}
            ).read_body
          end
        else
          Txter.log "Would have sent to 4info.net: #{body}"
        end
      end
      
      def start
        net = config.proxy_address ?
                Net::HTTP::Proxy(
                  config.proxy_address,
                  config.proxy_port,
                  config.proxy_username,
                  config.proxy_password) :
                Net::HTTP
        net.start(Txter.gateway.host, Txter.gateway.port) do |http|
          yield http
        end
      end
  end
end