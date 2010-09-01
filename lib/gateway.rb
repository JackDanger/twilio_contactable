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

      def initiate_voice_call(record, to, from = nil)

        url = TwilioContactable.configuration.controller_url || 'twilio_contactable'
        url = "#{url}/start_voice_confirmation?contactable_type=#{record.class}&contactable_id=#{record.id}"
        url = "/#{url}" unless url =~ /^\//

        deliver :voice,
                'To' => to,
                'From' => from,
                'Url' => url
      end

      def deliver_sms(message, to, from = nil)
        deliver :sms,
                'Message' => message,
                'To' => to,
                'From' => from
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

        def deliver(type, data = {})

          data['From'] = TwilioContactable.configuration.default_from_phone_number if data['From'].blank?
          raise "'From' number required for Twilio" unless data['From']

          service = case type
          when :sms
            'SMS/Messages'
          when :voice
            'Calls'
          end

          response = post service, data
 
          Net::HTTPCreated == response.code_type ?
                                TwilioContactable::Gateway::Success :
                                TwilioContactable::Gateway::Error
        end

        def post(service, data = {})
          account.request "/#{API_VERSION}/Accounts/#{TwilioContactable.configuration.client_id}/#{service}",
                          "POST",
                          data
        end
    end
  end
end
