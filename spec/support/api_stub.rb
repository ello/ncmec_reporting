class NcmecReporting::APIStub
  module Helpers
    def with_api_stub_flag(flag)
      NcmecReporting::APIStub.send("#{flag}=", true)
      yield
      NcmecReporting::APIStub.send("#{flag}=", false)
    end
  end

  class << self
    attr_accessor :invalid_status, :invalid_submit, :invalid_upload,
                  :invalid_fileinfo, :invalid_finish, :invalid_retract
  end

  def status(*)
    if self.class.invalid_status
      invalid_status
    else
      valid_status
    end
  end

  def submit(*)
    if self.class.invalid_submit
      invalid_response
    else
      valid_submit
    end
  end

  def upload(*)
    if self.class.invalid_upload
      invalid_response
    else
      valid_upload
    end
  end

  def fileinfo(*)
    if self.class.invalid_fileinfo
      invalid_response
    else
      valid_fileinfo
    end
  end

  def finish(*)
    if self.class.invalid_finish
      invalid_finish
    else
      valid_finish
    end
  end

  def retract(*)
    if self.class.invalid_retract
      invalid_response
    else
      valid_retract
    end
  end

  private

  def valid_status
    Nokogiri::XML(
      <<-XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <reportResponse>
          <responseCode>0</responseCode>
          <responseDescription>
            Remote User : testuser, Remote Ip : 1.2.3.4
          </responseDescription>
        </reportResponse>
      XML
    )
  end

  def invalid_status
    Nokogiri::XML(
      <<-XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <reportResponse>
          <responseCode>1000</responseCode>
          <responseDescription>Authentication Required</responseDescription>
        </reportResponse>
      XML
    )
  end

  def valid_submit
    Nokogiri::XML(
      <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <reportResponse>
          <responseCode>0</responseCode>
          <responseDescription></responseDescription>
          <reportId>1234</reportId>
        </reportResponse>
      XML
    )
  end

  def valid_upload
    Nokogiri::XML(
      <<-XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <reportResponse>
          <responseCode>0</responseCode>
          <responseDescription>Success</responseDescription>
          <reportId>1234</reportId>
          <fileId>5678</fileId>
          <hash>fafa5efeaf3cbe3b23b2748d13e629a1</hash>
        </reportResponse>
      XML
    )
  end

  def valid_fileinfo
    Nokogiri::XML(
      <<-XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <reportResponse>
          <responseCode>0</responseCode>
          <responseDescription>Success</responseDescription>
          <reportId>1234</reportId>
          <fileId>5678</fileId>
        </reportResponse>
      XML
    )
  end

  def valid_finish
    Nokogiri::XML(
      <<-XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <reportDoneResponse>
          <responseCode>0</responseCode>
          <reportId>1234</reportId>
          <files>
            <fileId>5678</fileId>
          </files>
        </reportDoneResponse>
      XML
    )
  end

  def invalid_finish
    Nokogiri::XML(
      <<-XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <reportDoneResponse>
          <responseCode>1000</responseCode>
          <responseDescription>You did it all wrong.</responseDescription>
        </reportDoneResponse>
      XML
    )
  end

  def valid_retract
    Nokogiri::XML(
      <<-XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <reportResponse>
          <responseCode>0</responseCode>
          <responseDescription>Success</responseDescription>
          <reportId>1234</reportId>
        </reportResponse>
      XML
    )
  end

  def invalid_response
    Nokogiri::XML(
      <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <reportResponse>
          <responseCode>1000</responseCode>
          <responseDescription>You did it all wrong.</responseDescription>
        </reportResponse>
      XML
    )
  end

end
