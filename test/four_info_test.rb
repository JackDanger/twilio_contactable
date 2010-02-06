require 'test_helper'


class FourInfoTest < ActiveSupport::TestCase

  context "contactable record" do
    setup { @user = User.create }
    should "have phone column" do
      assert @user.attribute_names.detect {|a| 'phone' == a}
    end
  end

end
