require File.join(File.dirname(__FILE__), 'test_helper')

class Gateway4InfoTest < ActiveSupport::TestCase

  ValidationError = '<?xml version="1.0" encoding="UTF-8"?>
<response>
  <status>
    <id>4</id>
    <message>Validation Error</message>
  </status>
</response>'
  ValidationSuccess = '<?xml version=”1.0” ?>
<response>
  <requestId>F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6</requestId>
  <confCode>123ABC</confCode>
  <status>
    <id>1</id>
    <message>Success</message>
  </status>
</response>'
  SendMsgSuccess = '<?xml version="1.0" ?>
<response>
  <requestId>F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6</requestId>
  <status>
    <id>1</id>
    <message>Success</message>
  </status>
</response>'
  UnblockSuccess = '<?xml version=”1.0” ?>
<response>
  <status>
    <id>1</id>
    <message>Success</message>
  </status>
</response>'


end