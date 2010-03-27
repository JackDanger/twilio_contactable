module Txter
  class Gateway4info < Txter::Gateway

    API = 'http://gateway.4info.net/msg'

    def self.deliver(message, number)
      Gateway4info.perform Request.new.deliver_message(message, number)
    end

    def self.perform(body)
      if :live == Txter.mode
        require 'net/http'
        uri = URI.parse API
        received = start do |http|
          http.post(
                     uri.path,
                     body,
                     {'Content-Type' => 'text/xml'}
          ).read_body
        end
        Response.new(received)
      else
        Txter.log "Would have sent to 4info.net: #{body}"
      end
    end
      
    protected

      def self.start
        c = Txter.configuration
        net = c.proxy_address ?
                Net::HTTP::Proxy(
                  c.proxy_address,
                  c.proxy_port,
                  c.proxy_username,
                  c.proxy_password) :
                Net::HTTP
        uri = URI.parse API
        net.start(uri.host, uri.port) do |http|
          yield http
        end
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
      attr_accessor :config

      def initialize
        unless Txter.configured?
          raise "You need to configure Txter before using it!"
        end
        self.config = Txter.configuration
      end

      def deliver_message(message, number)
        self.number  = Txter.internationalize(number)
        self.message = message

        template(:deliver).render(self)
      end

      def confirm(number)
        self.number  = Txter.internationalize(number)

        template(:confirm).render(self)
      end

      def unblock(number)
        self.number = Txter.internationalize(number)

        template(:unblock).render(self)
      end

      protected

        def template(name)
          # Haml templates for XML
          require 'cgi'
          templates = Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), '4info_templates', '*.haml')))
          file = templates.detect {|t| File.basename(t).chomp('.haml').to_sym == name.to_sym }
          raise ArgumentError, "Missing 4Info template: #{name}" unless file
          Haml::Engine.new(File.read(file))
        end
    end
  end
end