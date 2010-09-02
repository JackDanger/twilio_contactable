module TwilioContactable
  module Controller

    def self.included(controller)
      controller.instance_eval do
        # the developer should specify which model(s) will be sought
        # when the app receives incoming requests.
        # See the 'Controller' part of the README for details
        protected
        def twilio_contactable(*klasses)
          @@contactable_classes = klasses
          name = self.name.underscore.chomp('_controller')
          klasses.each do |klass|
            klass.twilio_contactable.controller = name
          end
        end
      end
    end

    def receive_sms_message
      unless defined?(@@contactable_classes) && !@@contactable_classes.blank?
        raise RuntimeError, "Please define which model(s) this controller should receive for via the 'twilio_contactable' method"
      end

      request = params[:request]
      render :text => 'unknown format', :status => 500 and return unless request
      case request['type']
      when 'BLOCK'
        @contactable = find_contactable_by_phone_number(request[:block][:recipient][:id])
        @contactable._TC_sms_blocked = true
        @contactable.save!
      when 'MESSAGE'
        @contactable = find_contactable_by_phone_number(request[:message][:sender][:id])
        if @contactable.respond_to?(:receive_sms)
          @contactable.receive_sms(request[:message][:text])
        else
          warn "An SMS message was received but #{@contactable.class.name.inspect} doesn't have a receive_sms method!"
        end
      end
      render :text => 'OK', :status => 200
    end

    def start_voice_confirmation
      render :xml => (Twilio::Response.new.tap do |response|
        gather(response)
      end.respond)
    end

    def receive_voice_confirmation
      @contactable = params[:contactable_type].constantize.find(params[:contactable_id])
      if @contactable.voice_confirm_with(params['Digits'])
        render :xml => (Twilio::Response.new.tap do |response|
          response.addSay "Thank you, please return to the website and continue"
          response.addHangup
        end.respond)
      else
        render :xml => (Twilio::Response.new.tap do |response|
          response.addSay "Sorry, those aren't the correct numbers."
          gather(response)
        end.respond)
      end
    end

    protected

      def gather(response)
        tries = (params[:tries] ||= '0').succ!
        if tries.to_i > 4
          response.addSay "We're sorry, this doesn't seem to be working. Please contact technical support."
          response.addHangup
        else
          response.addGather(
                :action => url_for(
                  :action => 'receive_voice_confirmation',
                  :contactable_type => params[:contactable_type],
                  :contactable_id   => params[:contactable_id],
                  :tries            => tries
                )
              ).tap do |gather|
            gather.addSay "Please type the numbers that appear on your screen, followed by the pound sign"
          end
        end
      end

      def find_contactable_by_phone_number(number)
        [number, number.sub(/^\+/,''), number.sub(/^\+1/,'')].uniq.compact.each do |possible_phone_number|
          @@contactable_classes.each do |klass|
            found = klass.find(
              :first,
              :conditions => 
                { klass.twilio_contactable.formatted_phone_number_column => possible_phone_number }
            )
            return found if found
          end
        end
        nil
      # rescue => error
      #   render :text => error.inspect
      end
  end
end