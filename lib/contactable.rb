module FourInfo
  module Contactable

    Attributes = [  :sms_phone_number,
                    :sms_blocked,
                    :sms_confirmation_code,
                    :sms_confirmation_attempted,
                    :sms_confirmed_phone_number ]

    def self.included(model)
      gem 'haml'
      require 'haml'
      require 'net/http'

      Attributes.each do |attribute|
        # add a method in the class for setting or retrieving
        # which column should be used for which attribute
        # 
        # :sms_phone_number_column defaults to :sms_phone_number, etc.
        model.instance_eval "
          def #{attribute}_column(value = nil)
            @#{attribute}_column ||= :#{attribute}
            @#{attribute}_column = value if value
            @#{attribute}_column
          end
        "
        # provide helper methods to access the right value
        # no matter which column it's stored in.
        #
        # e.g.: @user.four_info_sms_confirmation_code
        #       == @user.send(User.sms_confirmation_code_column)
        model.class_eval "
          def four_info_#{attribute}
            send self.class.#{attribute}_column
          end
          alias_method :four_info_#{attribute}?, :four_info_#{attribute}
          def four_info_#{attribute}=(value)
            send self.class.#{attribute}_column.to_s+'=', value
          end
        "
      end

      # normalize the phone number before it's saved in the database
      # (only for model classes using callbacks a la ActiveRecord,
      #  other folks will have to do this by hand)
      if model.respond_to?(:before_save)
        model.before_save :normalize_sms_phone_number
        model.class_eval do
          def normalize_sms_phone_number
            self.four_info_sms_phone_number = FourInfo.numerize(four_info_sms_phone_number)
          end
        end
      end
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
      return false if msg.to_s.strip.blank? || four_info_sms_blocked?
      return false unless sms_confirmed?

      # split into pieces that fit as individual messages.
      msg.to_s.scan(/.{1,160}/m).map do |text|
        FourInfo::Request.new.deliver_message(text, four_info_sms_phone_number).success?
      end
    end

    # Sends an SMS validation request via xml to the 4info gateway.
    # If request succeeds the 4info-generated confirmation code is saved
    # in the contactable record.
    def send_sms_confirmation!
      return false if four_info_sms_blocked?
      return true  if sms_confirmed?
      return false if four_info_sms_phone_number.blank?

      # If we're using a custom short code we'll
      # need to create a custom configuration message
      FourInfo.configuration.short_code ?
        confirm_four_info_sms_with_custom_message :
        confirm_four_info_sms_with_default_message
    end


    # Sends an unblock request via xml to the 4info gateway.
    # If request succeeds, changes the contactable record's
    # sms_blocked_column to false.
    def unblock_sms!
      return false unless four_info_sms_blocked?

      response = FourInfo::Request.new.unblock(four_info_sms_phone_number)
      if response.success?
        self.four_info_sms_blocked = 'false'
        save
      else
        false
      end
    end

    # Compares user-provided code with the stored confirmation
    # code. If they match then the current phone number is set
    # as confirmed by the user.
    def sms_confirm_with(code)
      if four_info_sms_confirmation_code == code
        # save the phone number into the 'confirmed phone number' attribute
        self.four_info_sms_confirmed_phone_number = four_info_sms_phone_number
        save
      else
        false
      end
    end

    # Returns true if the current phone number has been confirmed by
    # the user for recieving TXT messages.
    def sms_confirmed?
      return false if four_info_sms_confirmed_phone_number.blank?
      four_info_sms_confirmed_phone_number == four_info_sms_phone_number
    end

    protected
      def confirm_four_info_sms_with_custom_message
        confirmation_code = FourInfo.generate_confirmation_code

        # Use this class' confirmation_message method if it
        # exists, otherwise use the generic message
        message = (self.class.respond_to?(:confirmation_message) ?
                     self.class :
                     FourInfo).confirmation_message(confirmation_code)

        if message.to_s.size > 160
          raise ArgumentError, "SMS Confirmation Message is too long."
        end

        response = FourInfo::Request.new.deliver_message(message, four_info_sms_phone_number)

        if response.success?
          update_four_info_sms_confirmation confirmation_code
        else
          # "Confirmation Failed: #{response['message'].inspect}"
          false
        end
      end

      def confirm_four_info_sms_with_default_message
        response = FourInfo::Request.new.confirm(four_info_sms_phone_number)

        if response.success?
          update_four_info_sms_confirmation response.confirmation_code
        else
          # "Confirmation Failed: #{response['message'].inspect}"
          false
        end
      end

      def update_four_info_sms_confirmation(new_code)
        self.four_info_sms_confirmation_code = new_code
        self.four_info_sms_confirmation_attempted = Time.now.utc
        self.four_info_sms_confirmed_phone_number = nil
        save
      end
  end  
end