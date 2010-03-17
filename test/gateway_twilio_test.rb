require File.join(File.dirname(__FILE__), 'test_helper')

class Gateway4infoTest < ActiveSupport::TestCase

  context "with twilio gateway" do
    setup {
      Txter.configure do |config|
        config.client_id  = 12345
        config.client_key = 'ABC123'
        config.gateway    = 'twilio'
      end
    }
    # TODO: figure out what's left to test
  end
end