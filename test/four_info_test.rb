require File.join(File.dirname(__FILE__), 'test_helper')

class FourInfoTest < ActiveSupport::TestCase

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

    setup { @user = User.first }
    context "when phone number is blank" do
      setup { @user.sms_phone_number = nil}
      context "confirming phone number" do
        setup { @user.confirm_sms! }
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
      context "sending message" do
        setup { @worked = @user.send_sms!('message') }
        should "not work" do assert !@worked end
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
    end

    context "when phone number exists" do
      setup { @user.sms_phone_number = "206-555-5555"}
      context "confirming phone number" do
        setup {
          FourInfo::Request.any_instance.stubs(:perform).returns(ValidationSuccess)
          @worked = @user.confirm_sms!
        }
        should "work" do assert @worked end
        should "save confirmation number in proper attribute" do
          assert @user.four_info_sms_confirmation_code
        end
        should_change "stored code" do
          @user.four_info_sms_confirmation_code
        end
        should "set sms_confirmed? to true" do
          assert @user.four_info_sms_confirmed?
        end
      end
      context "confirming phone number when the confirmation fails for some reason" do
        setup {
          FourInfo::Request.any_instance.stubs(:perform).returns(ValidationError)
          @worked = @user.confirm_sms!
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
        setup { @result = @user.send_sms!('message') }
        should "send send no messages" do
          assert_equal false, @result
        end
      end
    end
    context "when the number is confirmed" do
      setup {
        FourInfo::Request.any_instance.stubs(:perform).returns(SendMsgSuccess)
        @user.update_attributes!(User.sms_confirmed_column => true)
      }
      context "sending a message" do
        setup {
          @result = @user.send_sms!('message')
        }
        should "send send exactly one message messages" do
          assert_equal [true], @result
        end
      end
    end
  end


  context "standardizing numbers" do
    context "to digits" do
      should "remove all but integers" do
        assert_equal '12345', FourInfo.numerize('1-2-3-4-5')
        assert_equal '12345', FourInfo.numerize('1 2 3 4 5')
        assert_equal '12345', FourInfo.numerize('1,2(3)4.5')
        assert_equal '12345', FourInfo.numerize('1,2(3)4.5')
      end
    end
    context "to international format" do
      should "add a '+' to all 11 digit numbers" do
        assert_equal '+12345678901', FourInfo.internationalize('12345678901')
        assert_equal '+72345678901', FourInfo.internationalize('72345678901')
      end
      should "add a '+1' to any 10 digit number" do
        assert_equal '+12345678901', FourInfo.internationalize('2345678901')
        assert_equal '+17345678901', FourInfo.internationalize('7345678901')
      end
      should "leave 12 digit numbers unchanged" do
        [ '+' + ('3'*11),
          '+' + ('8'*11),
          '+' + ('4'*11) ].each do |number|
          assert_equal number, FourInfo.internationalize(number)
        end
      end
      should "return nil for all bad numbers" do
        assert_equal nil, FourInfo.internationalize(nil)
        assert_equal nil, FourInfo.internationalize('nil')
        assert_equal nil, FourInfo.internationalize('1234')
        assert_equal nil, FourInfo.internationalize('11111111111111111111111')
        assert_equal nil, FourInfo.internationalize('what?')
      end
    end
  end
end
