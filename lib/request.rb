module FourInfo
  class Request

    # Haml templates for XML
    @@templates = Dir.glob(File.expand_path(File.join(File.dirname(__FILE__), 'templates', '*.haml')))

    # YML config files
    @@test_mode_config_file = File.join(File.dirname(__FILE__), '..', 'test', 'sms.yml')
    @@likely_config_files = [
        File.join(File.dirname(__FILE__), '..', 'sms.yml'),
        defined?(Rails) ? File.join(Rails.root, 'config', 'sms.yml') : '',
        File.join('config', 'sms.yml'),
        'sms.yml'
    ]

    attr_accessor :config
    attr_accessor :number
    attr_accessor :message

    def initialize
      config_file = :live == FourInfo.mode.to_sym ?
                      @@likely_config_files.detect {|f| File.exist?(f) } :
                      @@test_mode_config_file

      raise "Missing config File! Please add sms.yml to ./config or the 4info directory" unless config_file

      @config = YAML.load(File.read(config_file))['4info'].with_indifferent_access
    end

    def deliver_message(message, number)
      self.number = FourInfo.internationalize(number)
      self.message = message

      xml = template(:deliver).render(self)
      Response.new(perform(xml))
    end

    def confirm(number)
      self.number = FourInfo.internationalize(number)

      xml = template(:confirm).render(self)
      Response.new(perform(xml))
    end

    def unblock(number)
      self.number = FourInfo.internationalize(number)

      xml = template(:unblock).render(self)
      Response.new(perform(xml))
    end

    protected

      def template(name)
        file = @@templates.detect {|t| File.basename(t).chomp('.haml').to_sym == name.to_sym }
        raise ArgumentError, "Missing 4Info template: #{name}" unless file
        Haml::Engine.new(File.read(file))
      end

      def perform(body)
        if :live == FourInfo.mode
          start do |http|
            http.post(
              FourInfo.gateway.path,
              body,
              {'Content-Type' => 'text/xml'}
            ).read_body
          end
        else
          FourInfo.log "Would have sent to 4info.net: #{body}"
        end
      end

      def start
        net = config[:proxy].blank? ?
                Net::HTTP :
                Net::HTTP::Proxy(*config[:proxy].split(":"))
        net.start(FourInfo.gateway.host, FourInfo.gateway.port) do |http|
          yield http
        end
      end
  end
end