module Txter
  class GatewayTwilio < Txter::Gateway

    API_VERSION   = '2008-08-01'

    class << self

      def deliver(message, to, from)
        post 'To'   => to,
             'From' => from,
             'Body' => message
      end

      def account
        @account ||= begin
          if Txter.configuration.client_id.blank? ||
             Txter.configuration.client_key.blank?
             raise "Add your Twilio account id (as client_id) and token (as client_key) to the Txter.configure block"
          end

          Twilio::RestAccount.new(
                      Txter.configuration.client_id,
                      Txter.configuration.client_key
                    )
        end
      end

      protected

        def post(data = {})
          account.request "/#{API_VERSION}/Accounts/#{Txter.configuration.client_id}/SMS/Messages",
                          "POST",
                          data
        end
    end
  end           
end
