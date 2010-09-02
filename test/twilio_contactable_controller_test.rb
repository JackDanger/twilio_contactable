require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class TwilioContactableController < ActionController::Base
  include TwilioContactable::Controller

  twilio_contactable User
end

begin
  ActionController::Routing::Routes
rescue
  Rails.application.routes
end.draw do |map|
  map.route ':controller/:action', :controller => 'twilio_contactable'
end

class UserWithSMSReceiving < User
  def receive_sms(message)
  end
end

class TwilioContactableControllerTest < ActionController::TestCase

  context "with a user" do
    setup {
      User.delete_all
      @user = User.create! :phone_number => '(206) 335-1596'
      # and we should be able to find @user by this formatted version
      @formatted_phone_number = "2063351596"
    }
    context "receiving sms message" do
      context "receiving BLOCK" do
        setup {
          post :receive_sms_message,
          # this is what an xml request will parse to:
          "request"=>{"block"=>{"recipient"=>{"property"=>{"name"=>"CARRIER", "value"=>"3"}, "id"=>"+1#{@formatted_phone_number}", "type"=>"5"}}, "type" => "BLOCK"}
        }
        should_respond_with :success
        should "block user" do
          assert @user.reload.sms_blocked?
        end
        should_change "user block status" do
          @user.reload.sms_blocked?
        end
      end
      context "receiving MESSAGE" do
        setup {
          # this is what an xml request will parse to:
          @receive_params = {"request"=>{"message"=>{"id" => "ABCDEFG", "recipient"=>{"type"=> "6", "id"=>"12345"}, "sender" => {"type" => "5", "id" => "+1#{@formatted_phone_number}", "property" => {"name" => "CARRIER", "value" => "5"}}, "text" => "This is a text message."}, "type" => "MESSAGE"}}
        }
        context "when the user is not set up to receive" do
          setup {
            @user.expects(:receive_sms).with("This is a text message.").never
            post :receive_sms_message, @receive_params
          }
          should_respond_with :success
          should "not block user" do
            assert !@user.reload.sms_blocked?
          end
        end
        context "when the user is set up to receive" do
          setup {
            User.delete_all
            @new_user = UserWithSMSReceiving.create!(:phone_number => @user.phone_number)
            UserWithSMSReceiving.any_instance.expects(:receive_sms).with("This is a text message.").once
            post :receive_sms_message, @receive_params
          }
          should_respond_with :success
          should "not block user" do
            assert !@new_user.reload.sms_blocked?
          end
        end
      end
    end
    context "initiating a digit-gathering call from Twilio" do
      setup {
        @receive_params = {"FromState"=>"WA", "CallerCountry"=>"US", "CallerZip"=>"98077", "ToState"=>"WA", "Caller"=>"+#{@formatted_phone_number}", "AccountSid"=>"SOME_ACCOUNT", "contactable_type"=>"User", "Direction"=>"outbound-api", "FromCity"=>"WOODINVILLE", "From"=>"+5555555555", "contactable_id"=>"1", "CallerCity"=>"WOODINVILLE", "FromCountry"=>"US", "FromZip"=>"98077", "CallStatus"=>"in-progress", "To"=>"+12069305710", "ToCity"=>"SEATTLE", "Called"=>"+12069305710", "CalledCountry"=>"US", "CalledZip"=>"98188", "ApiVersion"=>"2010-04-01", "CalledCity"=>"SEATTLE", "CallSid"=>"CA76af6e953077fc478c9f2eb330484ea7", "CalledState"=>"WA", "ToCountry"=>"US", "ToZip"=>"98188", "CallerState"=>"WA"}
        get :start_voice_confirmation, @receive_params
      }
      should_respond_with :success
      should_respond_with_content_type :xml
      should "render Gather TwiML node with a Say inside" do
        assert_dom_equal %q{
        <response>
          <gather
            action="http://test.host/twilio_contactable/receive_voice_confirmation?contactable_id=1&amp;contactable_type=User"
            >
            <say>
              Please type the numbers that appear on your screen, followed by the pound sign
            </say>
          </gather>
          <say>
            Thank you, please return to the website and continue
          </say>
          <pause></pause>
        </response>
      }, @response.body
      end
    end
    context "receiving digits from Twilio" do
      setup {
        @digits = '12345'
        @user = User.create! :phone_number => '206 555 6666',
                             :voice_confirmation_code => @digits
        @receive_params = {"contactable_type"=>"User", "contactable_id"=>@user.id, "Digits"=>@digits, "FromState"=>"WA", "Direction"=>"outbound-api", "CalledState"=>"WA", "ToState"=>"WA", "AccountSid"=>"ABCDEFG", "CallerCountry"=>"US", "CallerZip"=>"98077", "Caller"=>"{number}", "FromCity"=>"WOODINVILLE", "From"=>"{number}", "action"=>"receive_voice_confirmation", "CallerCity"=>"WOODINVILLE", "FromCountry"=>"US", "FromZip"=>"98077", "To"=>"+12069305710", "ToCity"=>"SEATTLE", "CallStatus"=>"in-progress", "controller"=>"twilio_contactable", "ToZip"=>"98188", "CalledZip"=>"98188", "CallerState"=>"WA", "CalledCity"=>"SEATTLE", "Called"=>"+12069305710", "CalledCountry"=>"US", "CallSid"=>"ABCD", "ToCountry"=>"US", "ApiVersion"=>"2010-04-01"}
        get :receive_voice_confirmation, @receive_params
      }
      should_respond_with :success
      should_respond_with_content_type :xml
      should "set the user to confirmed via voice" do
        assert @user.reload.voice_confirmed?
      end
      should "not change the user's sms confirmation setting" do
        assert !@user.sms_confirmed?
      end
    end
  end
end
