require File.join(File.dirname(__FILE__), 'test_helper')

class FourInfoModuleTest < ActiveSupport::TestCase

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

  context "generating codes" do
    setup { @code = FourInfo.generate_confirmation_code }
    should "be 6 digits" do
      assert_equal 6, @code.length
    end
  end
end
