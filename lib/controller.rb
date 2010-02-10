module FourInfo
  module Controller
    def index
      recieve_xml
    end

    # in case this is hooked up as a RESTful route
    def create
      recieve_xml
    end

    protected

      def recieve_xml
        STDOUT.puts params.inspect
        render :text => response.inspect
      end
  end
end