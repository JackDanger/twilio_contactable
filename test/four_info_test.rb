require 'test_helper'

class FourInfoTest < ActiveSupport::TestCase

  context "contactable record" do
    FourInfo::Contactable::Attributes.each do |attribute|
      should "allow setting #{attribute}_column" do
        # check for appropriate default
        assert_equal attribute, User.send("#{attribute}_column")

        # set to new value
        new_column_name = :new_column
        User.send "#{attribute}_column", new_column_name
        assert_equal new_column_name, User.send("#{attribute}_column")
      end
    end
  end
end
