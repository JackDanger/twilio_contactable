module FourInfo
  module Controller
    def index
      process
    end

    # in case this is hooked up as a RESTful route
    def create
      process
    end

    protected

      def process
        STDOUT.puts params.inspect
      end
  end
end