module Txter
  class Request

    attr_accessor :config
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

      def perform(body)
        if :live == Txter.mode
          Txter.gateway.perform
        else
          Txter.log "Would have sent to 4info.net: #{body}"
        end
      end
  end
end
