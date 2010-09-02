require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class TwilioContactableContactableTest < ActiveSupport::TestCase

  Success = TwilioContactable::Gateway::Response.new(:status => :success)
  Error   = TwilioContactable::Gateway::Response.new(:status => :error)

  context "configuration" do
    TwilioContactable::Contactable::Attributes.each do |attr|
      context "attribute: #{attr}" do
        should "begin with appropriate default for #{attr}_column and allow overwriting" do
          klass = Class.new
          klass.send :include, TwilioContactable::Contactable
          assert_equal attr, klass.twilio_contactable.send("#{attr}_column")
          klass.twilio_contactable do |config|
            config.send("#{attr}_column=", :custom_column)
          end
          assert_equal :custom_column, klass.twilio_contactable.send("#{attr}_column")
        end
      end
    end
  end

  context "contactable instance" do
    setup {
      User.delete_all
      @user = User.create! :phone_number => '(555) 123-4567'
    }

    should "normalize phone number" do
      assert_equal '+15551234567', @user.formatted_phone_number
    end
    context "when phone number is blank" do
      setup { @user._TC_phone_number = nil}
      context "confirming phone number" do
        setup { @user.send_sms_confirmation! }
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
      context "sending message" do
        setup {
          TwilioContactable::Gateway.stubs(:perform).returns(Success)
          @worked = @user.send_sms!('message')
        }
        should "not work" do assert !@worked end
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
    end

    context "when phone number exists" do
      setup { @user._TC_phone_number = "206-555-5555"}
      context "confirming phone number" do
        context "via sms" do
          setup {
            TwilioContactable::Gateway.stubs(:deliver).returns(Success)
            @worked = @user.send_sms_confirmation!
          }
          should "work" do assert @worked end
          should "save confirmation number in proper attribute" do
            assert @user._TC_sms_confirmation_code
          end
          should "set confirmation attempted time" do
            assert @user._TC_sms_confirmation_attempted > 3.minutes.ago
          end
          should_change "stored code" do
            @user._TC_sms_confirmation_code
          end
          should "not have number confirmed yet" do
            assert !@user.sms_confirmed?
          end
          context "calling sms_confirm_with(right_code)" do
            setup { @user.sms_confirm_with(@user._TC_sms_confirmation_code) }
            should "work" do
              assert @worked
            end
            should "save the phone number into the confirmed attribute" do
              assert_equal @user._TC_phone_number,
                           @user._TC_sms_confirmed_phone_number,
                           @user.reload.inspect
            end
            should_change "confirmed phone number attribute" do
              @user._TC_sms_confirmed_phone_number
            end
            context "and then attempting to confirm another number" do
              setup {
                @user._TC_phone_number = "206-555-8990"
                TwilioContactable::Gateway.stubs(:deliver).returns(Success).once
                @user.send_sms_confirmation!
              }
              should "eliminate the previous confirmed phone number" do
                assert @user._TC_sms_confirmed_phone_number.blank?
              end
              should "un-confirm the record" do
                assert !@user.sms_confirmed?
              end
            end
          end
          context "calling sms_confirm_with(right code, wrong case)" do
            setup {
              @downcased_code = @user._TC_sms_confirmation_code.downcase
              @worked = @user.sms_confirm_with(@downcased_code)
            }
            should "have good test data" do
              assert_not_equal @downcased_code,
                               @user._TC_sms_confirmation_code
            end
            should "work" do
              assert @worked
            end
            should "save the phone number into the confirmed attribute" do
              assert_equal @user._TC_sms_confirmed_phone_number,
                           @user._TC_phone_number
            end
          end
          context "calling sms_confirm_with(wrong_code)" do
            setup { @worked = @user.sms_confirm_with('wrong_code') }
            should "not work" do
              assert !@worked
            end
            should "not save the phone number into the confirmed attribute" do
              assert_not_equal @user._TC_sms_confirmed_phone_number,
                               @user._TC_phone_number
            end
            should_not_change "confirmed phone number attribute" do
              @user.reload._TC_sms_confirmed_phone_number
            end
          end
        end
        context "confirming phone number with a custom short code" do
          context "with expectations" do
            setup {
              message = "long message blah blah MYCODE blah"
              TwilioContactable.expects(:generate_confirmation_code).returns('MYCODE').once
              TwilioContactable.expects(:confirmation_message).returns(message).once
              TwilioContactable::Gateway.expects(:deliver).with(message, @user._TC_phone_number).once
              @user.send_sms_confirmation!
            }
          end
          context "(normal)" do
            setup {
              TwilioContactable::Gateway.stubs(:deliver).returns(Success)
              @worked = @user.send_sms_confirmation!
            }
            should "work" do
              assert @worked
            end
          end
        end
        context "confirming phone number when the confirmation fails for some reason" do
          setup {
            TwilioContactable::Gateway.stubs(:deliver).returns(Error)
            @worked = @user.send_sms_confirmation!
          }
          should "not work" do assert !@worked end
          should "not save confirmation number" do
            assert @user._TC_sms_confirmation_code.blank?
          end
          should_not_change "stored code" do
            @user._TC_sms_confirmation_code
          end
        end
        context "via voice" do
          setup {
            TwilioContactable::Gateway.stubs(:deliver).returns(Success)
            # To start any voice call we'll need to first initialize
            # this model in a controller
            class TestController < ActionController::Base
              include TwilioContactable::Controller
              twilio_contactable User
              self
            end
            @worked = @user.send_voice_confirmation!
          }
          should "work" do assert @worked end
          should "save confirmation number in proper attribute" do
            assert @user._TC_voice_confirmation_code
          end
          should "set confirmation attempted time" do
            assert @user._TC_voice_confirmation_attempted > 3.minutes.ago
          end
          should_change "stored code" do
            @user._TC_voice_confirmation_code
          end
          should "not have number confirmed yet" do
            assert !@user.voice_confirmed?
          end
          context "calling voice_confirm_with(right_code)" do
            setup { @user.voice_confirm_with(@user._TC_voice_confirmation_code) }
            should "work" do
              assert @worked
            end
            should "save the phone number into the confirmed attribute" do
              assert_equal @user._TC_phone_number,
                           @user._TC_voice_confirmed_phone_number,
                           @user.reload.inspect
            end
            should_change "confirmed phone number attribute" do
              @user._TC_voice_confirmed_phone_number
            end
            context "and then attempting to confirm another number" do
              setup {
                @user._TC_phone_number = "206-555-8990"
                TwilioContactable::Gateway.stubs(:deliver).returns(Success).once
                @user.send_voice_confirmation!
              }
              should "eliminate the previous confirmed phone number" do
                assert @user._TC_voice_confirmed_phone_number.blank?
              end
              should "un-confirm the record" do
                assert !@user.voice_confirmed?
              end
            end
          end
          context "calling voice_confirm_with(right code, wrong case)" do
            setup {
              @downcased_code = @user._TC_voice_confirmation_code.downcase
              @worked = @user.voice_confirm_with(@downcased_code)
            }
            should "have good test data" do
              assert_not_equal @downcased_code,
                               @user._TC_voice_confirmation_code
            end
            should "work" do
              assert @worked
            end
            should "save the phone number into the confirmed attribute" do
              assert_equal @user._TC_voice_confirmed_phone_number,
                           @user._TC_phone_number
            end
          end
          context "calling voice_confirm_with(wrong_code)" do
            setup { @worked = @user.voice_confirm_with('wrong_code') }
            should "not work" do
              assert !@worked
            end
            should "not save the phone number into the confirmed attribute" do
              assert_not_equal @user._TC_voice_confirmed_phone_number,
                               @user._TC_phone_number
            end
            should_not_change "confirmed phone number attribute" do
              @user.reload._TC_voice_confirmed_phone_number
            end
          end
        end
      end
    end

    context "when the number is not confirmed" do
      context "sending a message" do
        setup {
          TwilioContactable::Gateway.stubs(:deliver).returns(Success)
          @result = @user.send_sms!('message')
        }
        should "send send no messages" do
          assert_equal false, @result
        end
      end
    end
    context "when the number is blocked" do
      setup {
        @user._TC_sms_blocked = true
        @user.save!
      }
      context "sending a message" do
        setup { @result = @user.send_sms!('message') }
        should "send nothing" do
          assert_equal false, @result
        end
      end
    end
    context "when the number is confirmed" do
      setup {
        TwilioContactable::Gateway.stubs(:deliver).returns(Success)
        @user.stubs(:sms_confirmed?).returns(true)
      }
      context "sending a message" do
        setup { @result = @user.send_sms!('message') }
        should "send send exactly one message" do
          assert_equal [7], @result
        end
      end
      context "sending a blank message" do
        setup { @result = @user.send_sms!('') }
        should "send send zero messages" do
          assert_equal false, @result
        end
      end
      context "sending a huge message" do
        context "without the allow_multiple flag" do
          should "raise an error" do
            assert_raises ArgumentError do
              @user.send_sms!("A"*200)
            end
          end
        end
        context "with the allow_multiple flag" do
          setup { @result = @user.send_sms!("A"*200, true) }
          should "send multiple messages" do
            assert_equal [160, 40], @result
          end
        end
      end
    end
  end
end