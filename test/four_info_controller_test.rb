require File.join(File.dirname(__FILE__), 'test_helper')
require 'action_pack'
require 'action_controller'
require 'shoulda/action_controller'
require 'shoulda/action_controller/macros'
require 'shoulda/action_controller/matchers'

class FourInfoController < ActionController::Base
  include FourInfo::Controller

  sms_contactable User
end
ActionController::Routing::Routes.draw do |map|
  map.route '*:url', :controller => 'four_info', :action => :index
end

class UserWithSMSReceiving < User
  def receive_sms(message)
  end
end

class FourInfoControllerTest < ActionController::TestCase

  context "with a user" do
    setup {
      User.delete_all
      @user = User.create! :sms_phone_number => '3334445555'
    }
    context "receiving BLOCK" do
      setup {
        post :index,
        # this is what an xml request will parse to:
        "request"=>{"block"=>{"recipient"=>{"property"=>{"name"=>"CARRIER", "value"=>"3"}, "id"=>"+1#{@user.sms_phone_number}", "type"=>"5"}}, "type" => "BLOCK"}
      }
      should_respond_with :success
      should "block user" do
        assert @user.reload.four_info_sms_blocked?
      end
      should_change "user block status" do
        @user.reload.four_info_sms_blocked?
      end
    end
    context "receiving MESSAGE" do
      setup {
        # this is what an xml request will parse to:
        @receive_params = {"request"=>{"message"=>{"id" => "ABCDEFG", "recipient"=>{"type"=> "6", "id"=>"12345"}, "sender" => {"type" => "5", "id" => "+1#{@user.sms_phone_number}", "property" => {"name" => "CARRIER", "value" => "5"}}, "text" => "This is a text message."}, "type" => "MESSAGE"}}
      }
      context "when the user is not set up to receive" do
        setup {
          @user.expects(:receive_sms).with("This is a text message.").never
          post :index,
          @receive_params
        }
        should_respond_with :success
        should "not block user" do
          assert !@user.reload.four_info_sms_blocked?
        end
      end
      context "when the user is set up to receive" do
        setup {
          User.delete_all
          @new_user = UserWithSMSReceiving.create!(:sms_phone_number => @user.sms_phone_number)
          UserWithSMSReceiving.any_instance.expects(:receive_sms).with("This is a text message.").once
          post :index,
          @receive_params
        }
        should_respond_with :success
        should "not block user" do
          assert !@new_user.reload.four_info_sms_blocked?
        end
      end
    end
  end
end
