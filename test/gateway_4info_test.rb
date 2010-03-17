require File.join(File.dirname(__FILE__), 'test_helper')

class Gateway4infoTest < ActiveSupport::TestCase

  Error = Txter::Gateway4info::Response.new('<?xml version="1.0" encoding="UTF-8"?>
<response>
  <status>
    <id>4</id>
    <message>Error</message>
  </status>
</response>')
  Success = Txter::Gateway4info::Response.new('<?xml version="1.0" ?>
<response>
  <requestId>F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6</requestId>
  <status>
    <id>1</id>
    <message>Success</message>
  </status>
</response>')

  context "with 4info gateway" do
    setup {
      Txter.configure do |config|
        config.client_id  = 12345
        config.client_key = 'ABC123'
        config.gateway    = '4info'
      end
    }
    context "with stubbed success" do
      setup {
        Txter::Gateway4info.stubs(:perform).returns(Success)
      }
      should "generate a success response object" do
        assert Txter.deliver("msg", "1-555-867-5309").success?
      end
    end
    context "with stubbed error" do
      setup {
        Txter::Gateway4info.stubs(:perform).returns(Error)
      }
      should "generate a success response object" do
        assert !Txter.deliver("msg", "1-555-867-5309").success?
      end
    end
    should "create proper xml for delivery" do
      expected = <<-EOXML
<?xml version='1.0' encoding='utf-8' ?>
<request clientId='12345' clientKey='ABC123' type='MESSAGE'>
  <message>
    <recipient>
      <type>5</type>
      <id>+15558675309</id>
    </recipient>
    <text>msg</text>
  </message>
</request>
EOXML
      assert_equal expected, Txter::Gateway4info::Request.new.deliver_message("msg", "1-555-867-5309")
    end
    should "create proper xml for unblock" do
      expected = <<-EOXML
<?xml version='1.0' encoding='utf-8' ?>
<request clientId='12345' clientKey='ABC123' type='UNBLOCK'>
  <unblock>
    <recipient>
      <type>5</type>
      <id>+15558675309</id>
    </recipient>
  </unblock>
</request>
EOXML
      assert_equal expected, Txter::Gateway4info::Request.new.unblock("1-555-867-5309")
    end
  end
end