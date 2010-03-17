require File.join(File.dirname(__FILE__), 'test_helper')

class Gateway4InfoTest < ActiveSupport::TestCase

  Error = '<?xml version="1.0" encoding="UTF-8"?>
<response>
  <status>
    <id>4</id>
    <message>Error</message>
  </status>
</response>'
  Success = '<?xml version="1.0" ?>
<response>
  <requestId>F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6</requestId>
  <status>
    <id>1</id>
    <message>Success</message>
  </status>
</response>'

  # TODO: test specific code within 4info gateway

end