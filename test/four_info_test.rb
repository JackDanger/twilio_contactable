require 'test_helper'


class FourInfoTest < ActiveSupport::TestCase

  context "contactable record" do
    setup { @user = User.create }
    should "have number column" do
      assert @user.columns.detect {|c| c.name == 'number'}
    end
  end

end
