module Txter
  class Gateway4info < Txter::Gateway
    def perform
      require 'net/http'
      uri = URI.parse 'http://gateway.4info.net/msg'
      start do |http|
        http.post(
                   uri.path,
                   body,
                   {'Content-Type' => 'text/xml'}
        ).read_body
      end
    end
      
    protected

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