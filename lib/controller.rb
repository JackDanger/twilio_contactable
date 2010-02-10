module FourInfo
  module Controller

    # the user should specify which class gets contacted
    def self.contactable(klass)
      @@contactable_class = klass
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
        request = params[:request]
        render :text => 'unknown format', :status => 500 and return unless request
        case request[:type]
        when 'BLOCK'
          @contactable = find_contactable(request[:block][:recipient][:id])
          @contactable.four_info_sms_blocked = true
          @contactable.save
        when 'MESSAGE'
          @contactable = find_contactable(request[:message][:sender][:id])
          if @contactable.respond_to?(:receive_sms)
            @contactable.receive_sms(request[:message][:text])
          else
            warn "An SMS message was received by #{@@contactable_klass.name} doesn't have a receive_sms method!"
          end
        end
        render :text => 'OK', :status => 200
      end

      def find_contactable(id)
        @@contactable_class.find(
          :first,
          :conditions => {
            @@contactable_class.sms_phone_number_column => id
          }
        )
      rescue => error
        render :text => error.inspect
      end
  end
end