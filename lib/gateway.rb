module TwilioContactable
  module Gateway
    class Response
      def initialize(*args)
        @options = args.last
      end

      def success?
        :success == @options[:status]
      end
    end
    Success = Response.new(:status => :success)
    Error   = Response.new(:status => :error)

    API_VERSION   = '2008-08-01'

    class << self

      def deliver(message, to, from = nil)

        from ||= TwilioContactable.configuration.default_from_phone_number
        raise "'From' number required for Twilio" unless from

        response = post 'To'   => to,
                       'From' => from,
                       'Body' => message

        Net::HTTPCreated == response.code_type ?
                              TwilioContactable::Gateway::Success :
                              TwilioContactable::Gateway::Error
      end

      def account
        @account ||= begin
          if TwilioContactable.configuration.client_id.blank? ||
             TwilioContactable.configuration.client_key.blank?
             raise "Add your Twilio account id (as client_id) and token (as client_key) to the TwilioContactable.configure block"
          end
          gem 'twiliolib'
          require 'twiliolib'
          Twilio::RestAccount.new(
                      TwilioContactable.configuration.client_id,
                      TwilioContactable.configuration.client_key
                    )
        end
      end

      protected

        def post(data = {})
          account.request "/#{API_VERSION}/Accounts/#{TwilioContactable.configuration.client_id}/SMS/Messages",
                          "POST",
                          data
        end
    end
  end
end
