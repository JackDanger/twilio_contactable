module TwilioContactable
  module Controller

    def self.included(controller)
      controller.instance_eval do
        # the developer should specify which model will be sought
        # when the app receives incoming requests
        protected
        def twilio_contactable(klass)
          @@contactable_class = klass
        end
      end
    end

    def receive_sms_message
      unless defined?(@@contactable_class)
        raise RuntimeError, "Please define which model this controller should receive for via the 'twilio_contactable' method"
      end

      request = params[:request]
      render :text => 'unknown format', :status => 500 and return unless request
      case request['type']
      when 'BLOCK'
        @contactable = find_contactable(request[:block][:recipient][:id])
        @contactable._TC_sms_blocked = true
        @contactable.save!
      when 'MESSAGE'
        @contactable = find_contactable(request[:message][:sender][:id])
        if @contactable.respond_to?(:receive_sms)
          @contactable.receive_sms(request[:message][:text])
        else
          warn "An SMS message was received but #{@@contactable_class.name.inspect} doesn't have a receive_sms method!"
        end
      end
      render :text => 'OK', :status => 200
    end

    def start_voice_confirmation
      render :xml => (Twilio::Response.new.tap do |response|
        response.addGather(
              :action => url_for(
                :action => 'receive_voice_confirmation',
                :contactable_id   => params[:contactable_id]
              )
            ).tap do |gather|
          gather.addSay "Please type the numbers that appear on your screen, followed by the pound sign"
        end
      end.respond)
    end

    def receive_voice_confirmation
      
    end

    protected

      def find_contactable(id)
        [id, id.sub(/^\+/,''), id.sub(/^\+1/,'')].uniq.compact.each do |possible_phone_number|
          found = @@contactable_class.find(
            :first,
            :conditions => 
              { @@contactable_class.twilio_contactable.formatted_phone_number_column => possible_phone_number }
          )
          return found if found
        end
        nil
      # rescue => error
      #   render :text => error.inspect
      end
  end
end