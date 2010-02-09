require 'test_helper'

class FourInfoTest < ActiveSupport::TestCase

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
      @user = User.new
    }
    context "when phone number is blank" do
      setup { @user.sms_phone_number = nil}
      context "confirming phone number" do
        setup { @user.confirm_sms! }
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
    end
    context "when phone number exists" do
      setup { @user.sms_phone_number = "206-555-5555"}
        should "save confirmation number in proper attribute" do
          assert @user.send(User.sms_confirmation_code_column)
        end
        should_change "stored code" do
          @user.send User.sms_confirmation_code_column
        end
      end
    end
  end
end
