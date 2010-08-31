module TwilioContactable
  module Controller

    def self.included(controller)
      controller.instance_eval do
        # the user should specify which class gets contacted
        def sms_contactable(klass)
          @@contactable_class = klass
        end
      end
    end

    # the likely default
    def index
      recieve_xml
    end

    # in case this is hooked up as a RESTful route
    def create
      recieve_xml
    end

    protected

      def recieve_xml

        unless defined?(@@contactable_class)
          raise RuntimeError, "Please define your user class in the TwilioContactable controller via the 'sms_contactable' method"
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