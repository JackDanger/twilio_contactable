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
        # add a method for setting or retrieving
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
        # provide a helper method to access the right value
        # no matter which column it's stored in
        #
        # e.g.: @user.four_info_sms_confirmation_code
        #       == @user.send(User.sms_confirmation_code_column)
        model.class_eval "
          def four_info_#{attribute}(value = nil)
            value ?
              send(self.class.#{attribute}_column.to_s+'=', value) :
              send(self.class.#{attribute}_column)
          end
          alias_method :four_info_#{attribute}?, :four_info_#{attribute}
          alias_method :four_info_#{attribute}=, :four_info_#{attribute}
        "
      end
    end

    def current_phone_number_confirmed_for_sms?
      return false if four_info_sms_confirmed_phone_number.blank?
      four_info_sms_confirmed_phone_number == four_info_sms_phone_number
    end

    def send_sms!(msg, allow_multiple = false)
      if msg.to_s.size > 160 && !allow_multiple
        raise ArgumentError, "SMS Message is too long. Either specify that you want multiple messages or shorten the string."
      end
      return false if msg.to_s.strip.blank? || four_info_sms_blocked?
      return false unless current_phone_number_confirmed_for_sms?

      # split into pieces that fit as individual messages.
      msg.to_s.scan(/.{1,160}/m).map do |text|
        FourInfo::Request.new.deliver_message(text, four_info_sms_phone_number).success?
      end
    end

    def send_sms_confirmation!
      return false if four_info_sms_blocked?
      return true  if current_phone_number_confirmed_for_sms?
      return false if four_info_sms_phone_number.blank?

      response = FourInfo::Request.new.confirm(four_info_sms_phone_number)
      if response.success?
        self.four_info_sms_confirmation_code response.confirmation_code
        self.four_info_sms_confirmation_attempted Time.now
        save
      else
        # "Confirmation Failed: #{response['message'].inspect}"
        false
      end
    end

    def sms_confirmed!
      # save the phone number into the 'confirmed phone number' attribute
      four_info_sms_confirmed_phone_number four_info_sms_phone_number
    end

    def unblock_sms!
      return false unless four_info_sms_blocked?

      response = FourInfo::Request.new.unblock(four_info_sms_phone_number)
      if response.success?
        four_info_sms_blocked 'false'
        save!
      else
        false
      end
    end
  end  
end