module NcmecReporting
  class Status
    def online?
      status = NcmecReporting::API.new.status
      response_code = status.xpath('//reportResponse/responseCode').text

      response_code == '0'
    end
  end
end
