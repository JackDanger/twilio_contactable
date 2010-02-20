require File.join(File.dirname(__FILE__), 'test_helper')

class FourInfoContactableTest < ActiveSupport::TestCase

  ValidationError = '<?xml version="1.0" encoding="UTF-8"?>
<response>
  <status>
    <id>4</id>
    <message>Validation Error</message>
  </status>
</response>'
  ValidationSuccess = '<?xml version=”1.0” ?>
<response>
  <requestId>F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6</requestId>
  <confCode>123abc</confCode>
  <status>
    <id>1</id>
    <message>Success</message>
  </status>
</response>'
  SendMsgSuccess = '<?xml version="1.0" ?>
<response>
  <requestId>F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6</requestId>
  <status>
    <id>1</id>
    <message>Success</message>
  </status>
</response>'
  UnblockSuccess = '<?xml version=”1.0” ?>
<response>
  <status>
    <id>1</id>
    <message>Success</message>
  </status>
</response>'


  context "contactable class" do
    setup {
      @klass = Class.new
      @klass.send :include, FourInfo::Contactable
    }
    FourInfo::Contactable::Attributes.each do |attribute|
      should "begin with appropriate default for #{attribute}_column" do
        assert_equal attribute, @klass.send("#{attribute}_column")
      end
      should "allow setting #{attribute}_column" do
        new_column_name = :custom_column
        @klass.send "#{attribute}_column", new_column_name
        assert_equal new_column_name, @klass.send("#{attribute}_column")
      end
    end
  end

  context "contactable instance" do
    setup {
      User.delete_all
      @user = User.create! User.sms_phone_number_column => '(555) 123-4567'
    }

    should "normalize phone number" do
      assert_equal '5551234567', @user.four_info_sms_phone_number
    end
    context "when phone number is blank" do
      setup { @user.four_info_sms_phone_number = nil}
      context "confirming phone number" do
        setup { @user.send_sms_confirmation!(OurConfirmationMessage) }
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
      context "sending message" do
        setup {
          FourInfo::Request.any_instance.stubs(:perform).returns(SendMsgSuccess)
          @worked = @user.send_sms!('message')
        }
        should "not work" do assert !@worked end
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
    end

    context "when phone number exists" do
      setup { @user.four_info_sms_phone_number = "206-555-5555"}
      context "confirming phone number" do
        setup {
          FourInfo::Request.any_instance.stubs(:perform).returns(ValidationSuccess)
          @worked = @user.send_sms_confirmation!(OurConfirmationMessage)
        }
        should "work" do assert @worked end
        should "save confirmation number in proper attribute" do
          assert_equal '123abc', @user.four_info_sms_confirmation_code
        end
        should "set confirmation attempted time" do
          assert @user.four_info_sms_confirmation_attempted > 3.minutes.ago
        end
        should_change "stored code" do
          @user.four_info_sms_confirmation_code
        end
        should "not have number confirmed yet" do
          assert !@user.sms_confirmed?
        end
        context "calling sms_confirm_with(right_code)" do
          setup { @user.sms_confirm_with(@user.four_info_sms_confirmation_code) }
          should "work" do
            assert @worked
          end
          should "save the phone number into the confirmed attribute" do
            assert_equal @user.four_info_sms_confirmed_phone_number,
                         @user.four_info_sms_phone_number
          end
          should_change "confirmed phone number attribute" do
            @user.four_info_sms_confirmed_phone_number
          end
          context "and then attempting to confirm another number" do
            setup {
              @user.four_info_sms_phone_number = "206-555-5555"
              FourInfo::Request.any_instance.expects(:perform).returns(ValidationSuccess).once
              @user.send_sms_confirmation!
            }
            should "eliminate the previous confirmed phone number" do
              assert @user.four_info_sms_confirmed_phone_number.blank?
            end
            should "un-confirm the record" do
              assert !@user.sms_confirmed?
            end
          end
        end
        context "calling sms_confirm_with(wrong_code)" do
          setup { @worked = @user.sms_confirm_with('wrong_code') }
          should "not work" do
            assert !@worked
          end
          should "not save the phone number into the confirmed attribute" do
            assert_not_equal @user.four_info_sms_confirmed_phone_number,
                             @user.four_info_sms_phone_number
          end
          should_not_change "confirmed phone number attribute" do
            @user.reload.four_info_sms_confirmed_phone_number
          end
        end
      end
      context "confirming phone number when the confirmation fails for some reason" do
        setup {
          FourInfo::Request.any_instance.stubs(:perform).returns(ValidationError)
          @worked = @user.send_sms_confirmation!
        }
        should "not work" do assert !@worked end
        should "not save confirmation number" do
          assert @user.four_info_sms_confirmation_code.blank?
        end
        should_not_change "stored code" do
          @user.four_info_sms_confirmation_code
        end
      end
    end

    context "when the number is not confirmed" do
      context "sending a message" do
        setup {
          FourInfo::Request.any_instance.stubs(:perform).returns(SendMsgSuccess)
          @result = @user.send_sms!('message')
        }
        should "send send no messages" do
          assert_equal false, @result
        end
      end
    end
    context "when the number is blocked" do
      setup {
        @user.four_info_sms_blocked = true
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
        FourInfo::Request.any_instance.stubs(:perform).returns(SendMsgSuccess)
        @user.stubs(:sms_confirmed?).returns(true)
      }
      context "sending a message" do
        setup { @result = @user.send_sms!('message') }
        should "send send exactly one message messages" do
          assert_equal [true], @result
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
            assert_equal [true, true], @result
          end
        end
      end
    end

    context "when the number is not blocked" do
      setup {
        FourInfo::Request.any_instance.expects(:perform).never
      }
      context "unblocking" do
        setup { @worked = @user.unblock_sms! }
        should "not do anything" do
          assert !@worked
        end
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
    end
    context "when the number is blocked" do
      setup {
        FourInfo::Request.any_instance.stubs(:perform).returns(UnblockSuccess)
        @user.update_attributes!(:sms_blocked => true)
      }
      context "unblocking" do
        setup { @worked = @user.unblock_sms! }
        should "work" do
          assert @worked
        end
        should_change "blocked attribute" do
          @user.reload.sms_blocked
        end
      end
    end
  end
end