module TwilioContactable
  module Contactable

    Attributes = [
      :phone_number,
      :formatted_phone_number,
      :sms_blocked,
      :sms_confirmation_code,
      :sms_confirmation_attempted,
      :sms_confirmed_phone_number,
      :voice_blocked,
      :voice_confirmation_code,
      :voice_confirmation_attempted,
      :voice_confirmed_phone_number
    ]

    class Configuration
      Attributes.each do |attr|
        attr_accessor "#{attr}_column"
      end

      def initialize

        yield self

        Attributes.each do |attr|
          # set the defaults if the user hasn't specified anything
          if send(attr).blank?
            send("#{attr}=", attr)
          end
        end
      end
    end

    def self.included(model)

      # set up the configuration, available within the class object
      # via this same 'twilio_contactable' method
      model.instance_eval do
        def twilio_contactable(&block)
          @@twilio_contactable ||= Configuration.new(&block)
        end
      end

      # normalize the phone number before it's saved in the database
      # (only for model classes using callbacks a la ActiveModel,
      #  other folks will have to do this by hand)
      if model.respond_to?(:before_save)
        model.before_save :format_phone_number
        model.class_eval do
          def format_phone_number
            twilio_contactable.formatted_phone_number =
              TwilioContactable.numerize(twilio_contactable.phone_number)
          end
        end
      end
    end

    # Set up a bridge to access the data for a specific instance
    # by referring to the column values in the configuration.
    Attributes.each do |attr|
      eval %Q{
        def _TC_#{attr}
          send self.class.twilio_contactable.#{attr}
        end
        def _TC_#{attr}=(value)
          send self.class.twilio_contactable.#{attr}.to_s + '=', value
        end
      }
    end


    # Sends one or more TXT messages to the contactable record's
    # mobile number (if the number has been confirmed).
    # Any messages longer than 160 characters will need to be accompanied
    # by a second argument <tt>true</tt> to clarify that sending
    # multiple messages is intentional.
    def send_sms!(msg, allow_multiple = false)
      if msg.to_s.size > 160 && !allow_multiple
        raise ArgumentError, "SMS Message is too long. Either specify that you want multiple messages or shorten the string."
      end
      return false if msg.to_s.strip.blank? || _TC_sms_blocked
      return false unless sms_confirmed?

      # split into pieces that fit as individual messages.
      msg.to_s.scan(/.{1,160}/m).map do |text|
        if TwilioContactable.deliver(text, _TC_phone_number).success?
          text.size
        else
          false
        end
      end
    end

    # Sends an SMS validation request through the gateway
    def send_sms_confirmation!
      return false if _TC_sms_blocked
      return true  if sms_confirmed?
      return false if _TC_phone_number.blank?

      confirmation_code = TwilioContactable.generate_confirmation_code

      # Use this class' confirmation_message method if it
      # exists, otherwise use the generic message
      message = (self.class.respond_to?(:confirmation_message) ?
                   self.class :
                   TwilioContactable).confirmation_message(confirmation_code)

      if message.to_s.size > 160
        raise ArgumentError, "SMS Confirmation Message is too long. Limit it to 160 characters of unescaped text."
      end

      response = TwilioContactable.deliver(message, _TC_phone_number)

      if response.success?
        update_twilio_contactable_sms_confirmation confirmation_code
      else
        false
      end
    end


    # Sends an unblock request to Twilio.
    # If request succeeds, changes the contactable record's
    # sms_blocked_column to false.
    def unblock_sms!
      return false unless _TC_sms_blocked

      response = TwilioContactable.unblock(_TC_phone_number)
      if response.success?
        self._TC_sms_blocked = false
        save
      else
        false
      end
    end

    # Compares user-provided code with the stored confirmation
    # code. If they match then the current phone number is set
    # as confirmed by the user.
    def sms_confirm_with(code)
      if _TC_sms_confirmation_code.to_s.downcase == code.downcase
        # save the phone number into the 'confirmed phone number' attribute
        _TC_sms_confirmed_phone_number = _TC_phone_number
        save
      else
        false
      end
    end

    # Returns true if the current phone number has been confirmed by
    # the user for recieving TXT messages.
    def sms_confirmed?
      return false if _TC_sms_confirmed_phone_number.blank?
      self._TC_sms_confirmed_phone_number == _TC_phone_number
    end

    protected

      def update_twilio_contactable_sms_confirmation(new_code)
        self._TC_sms_confirmation_code = new_code
        self._TC_sms_confirmation_attempted = Time.now.utc
        self._TC_sms_confirmed_phone_number = nil
        save
      end
  end  
end