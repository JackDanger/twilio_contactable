require File.join(File.dirname(__FILE__), 'test_helper')

class TxterContactableTest < ActiveSupport::TestCase

  Success = Txter::Gateway::Response.new(:status => :success)
  Error   = Txter::Gateway::Response.new(:status => :error)

  context "contactable class" do
    setup {
      @klass = Class.new
      @klass.send :include, Txter::Contactable
    }
    Txter::Contactable::Attributes.each do |attribute|
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
      assert_equal '5551234567', @user.txter_sms_phone_number
    end
    context "when phone number is blank" do
      setup { @user.txter_sms_phone_number = nil}
      context "confirming phone number" do
        setup { @user.send_sms_confirmation! }
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
      context "sending message" do
        setup {
          Txter.gateway.stubs(:perform).returns(Success)
          @worked = @user.send_sms!('message')
        }
        should "not work" do assert !@worked end
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
    end

    context "when phone number exists" do
      setup { @user.txter_sms_phone_number = "206-555-5555"}
      context "confirming phone number" do
        setup {
          Txter::Request.any_instance.stubs(:perform).returns(Success)
          @worked = @user.send_sms_confirmation!
        }
        should "work" do assert @worked end
        should "save confirmation number in proper attribute" do
          assert @user.txter_sms_confirmation_code
        end
        should "set confirmation attempted time" do
          assert @user.txter_sms_confirmation_attempted > 3.minutes.ago
        end
        should_change "stored code" do
          @user.txter_sms_confirmation_code
        end
        should "not have number confirmed yet" do
          assert !@user.sms_confirmed?
        end
        context "calling sms_confirm_with(right_code)" do
          setup { @user.sms_confirm_with(@user.txter_sms_confirmation_code) }
          should "work" do
            assert @worked
          end
          should "save the phone number into the confirmed attribute" do
            assert_equal @user.txter_sms_confirmed_phone_number,
                         @user.txter_sms_phone_number
          end
          should_change "confirmed phone number attribute" do
            @user.txter_sms_confirmed_phone_number
          end
          context "and then attempting to confirm another number" do
            setup {
              @user.txter_sms_phone_number = "206-555-5555"
              Txter.stubs(:deliver).returns(Success).once
              @user.send_sms_confirmation!
            }
            should "eliminate the previous confirmed phone number" do
              assert @user.txter_sms_confirmed_phone_number.blank?
            end
            should "un-confirm the record" do
              assert !@user.sms_confirmed?
            end
          end
        end
        context "calling sms_confirm_with(right code, wrong case)" do
          setup {
            @downcased_code = @user.txter_sms_confirmation_code.downcase
            @worked = @user.sms_confirm_with(@downcased_code)
          }
          should "have good test data" do
            assert_not_equal @downcased_code,
                             @user.txter_sms_confirmation_code
          end
          should "work" do
            assert @worked
          end
          should "save the phone number into the confirmed attribute" do
            assert_equal @user.txter_sms_confirmed_phone_number,
                         @user.txter_sms_phone_number
          end
        end
        context "calling sms_confirm_with(wrong_code)" do
          setup { @worked = @user.sms_confirm_with('wrong_code') }
          should "not work" do
            assert !@worked
          end
          should "not save the phone number into the confirmed attribute" do
            assert_not_equal @user.txter_sms_confirmed_phone_number,
                             @user.txter_sms_phone_number
          end
          should_not_change "confirmed phone number attribute" do
            @user.reload.txter_sms_confirmed_phone_number
          end
        end
      end
      context "confirming phone number with a custom short code" do
        context "with expectations" do
          setup {
            Txter.configure do |config|
              config.short_code = '0005'
              config.gateway    = 'test'
              config.client_id  = 1
              config.client_key = 'ABC123'
            end
            message = "long message blah blah MYCODE blah"
            Txter.expects(:generate_confirmation_code).returns('MYCODE').once
            Txter.expects(:confirmation_message).returns(message).once
            Txter::Request.any_instance.expects(:deliver_message).with(message, @user.txter_sms_phone_number).once
            @user.send_sms_confirmation!
          }
        end
        context "(normal)" do
          setup {
            Txter.configure do |config|
              config.short_code = '0005'
              config.gateway    = 'test'
              config.client_id  = 1
              config.client_key = 'ABC123'
            end
            Txter::Request.any_instance.stubs(:perform).returns(Success)
            @worked = @user.send_sms_confirmation!
          }
          should "work" do
            assert @worked
          end
        end
      end
      context "confirming phone number when the confirmation fails for some reason" do
        setup {
          Txter.stubs(:deliver).returns(Error)
          @worked = @user.send_sms_confirmation!
        }
        should "not work" do assert !@worked end
        should "not save confirmation number" do
          assert @user.txter_sms_confirmation_code.blank?
        end
        should_not_change "stored code" do
          @user.txter_sms_confirmation_code
        end
      end
    end

    context "when the number is not confirmed" do
      context "sending a message" do
        setup {
          Txter::Request.any_instance.stubs(:perform).returns(Success)
          @result = @user.send_sms!('message')
        }
        should "send send no messages" do
          assert_equal false, @result
        end
      end
    end
    context "when the number is blocked" do
      setup {
        @user.txter_sms_blocked = true
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
        Txter::Request.any_instance.stubs(:perform).returns(Success)
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

    context "when the number is not blocked" do
      setup {
        Txter::Request.any_instance.expects(:perform).never
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
        Txter::Request.any_instance.stubs(:perform).returns(Success)
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