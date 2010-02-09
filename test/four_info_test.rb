require 'test_helper'

class FourInfoTest < ActiveSupport::TestCase

  context "contactable record" do
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
end
