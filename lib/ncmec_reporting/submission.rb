require 'ncmec_reporting/submission/state'

module NcmecReporting
  class Submission

    PORN = 'Child Pornography (possession, manufacture, and distribution)'
    TRAFFICKING = 'Child Sex Trafficking'
    TOURISM = 'Child Sex Tourism'
    MOLESTATION = 'Child Sexual Molestation (not by family member)'
    MISLEADING_DOMAIN = 'Misleading Domain Name'
    MISLEADING_CONTENT = 'Misleading Words or Digital Images on the Internet'
    ENTICEMENT = 'Online Enticement of Children for Sexual Acts'
    OBSCENE_MATERIAL = 'Unsolicited Obscene Material Sent to a Child'

    def initialize(api = NcmecReporting::API.new)
      @state = State.new
      @api = api
    end

    def submit(report)
      @state.submit

      validate_report(report)

      Configuration.logger.info "[NCMEC] Submitting new report"
      Configuration.logger.debug "[NCMEC] #{report.to_s}"

      response = @api.submit(report)
      validate_response(response)

      @report_id = response.xpath('//reportResponse/reportId').text

      Configuration.logger.info "[NCMEC] [REPORT #{@report_id}] Report created"

      @quarantine = Configuration.quarantine_adapter.new(@report_id)
      @quarantine.store_text('report.xml', report)

      @report_id
    end

    def upload(file)
      @state.upload

      Configuration.logger.info "[NCMEC] [REPORT #{@report_id}] Uploading file"

      uploaded_file = @api.upload(@report_id, file)
      validate_response(uploaded_file)

      file_id = uploaded_file.xpath('//reportResponse/fileId').text
      file.file_id = file_id

      Configuration.logger.info "[NCMEC] [REPORT #{@report_id}] [FILE #{file_id}] File uploaded"

      upload_fileinfo(file_id, file.fileinfo) if file.fileinfo

      @quarantine.store_assets(file)

      file_id
    end

    def finish
      @state.finish

      Configuration.logger.info "[NCMEC] [REPORT #{@report_id}] Finishing"

      response = @api.finish(@report_id)
      validate_response(response, 'reportDoneResponse')

      @quarantine.upload

      response
    end

    def retract
      @state.retract

      Configuration.logger.info "[NCMEC] [REPORT #{@report_id}] Retracting"

      response = @api.retract(@report_id)
      validate_response(response)

      response
    end

    private

    def validate_report(report)
      unless report_valid?(report)
        raise InvalidReport.new('You must provide incidentType, incidentDateTime and reportingPerson as part of the report')
      end
    end

    def report_valid?(report)
      # TODO this should do real validation
      # against XSD
      # and worst case we should do something like
      # doc.at_css('reportingPerson email')
      report.include?('incidentSummary') &&
      report.include?('incidentType') &&
      report.include?('incidentDateTime') &&

      report.include?('reporter') &&
      report.include?('reportingPerson')
      report.include?('email')
    end

    def upload_fileinfo(file_id, fileinfo)
      xml = Nokogiri::XML(fileinfo.xml)

      report_id_node = Nokogiri::XML::Node.new 'reportId', xml
      report_id_node.content = @report_id

      file_id_node = Nokogiri::XML::Node.new 'fileId', xml
      file_id_node.content = file_id

      # reportId and fileId must be added to the doc, in that order.
      root = xml.xpath('//fileDetails')
      root.children.first.add_previous_sibling(file_id_node)
      root.children.first.add_previous_sibling(report_id_node)

      Configuration.logger.info "[NCMEC] [REPORT #{@report_id}] [FILE #{file_id}] Uploading file metadata"
      Configuration.logger.debug "[NCMEC] [REPORT #{@report_id}] [FILE #{file_id}] #{xml.to_s}"

      @api.fileinfo(xml.to_s).tap do |response|
        validate_response(response)
      end
    end

    def validate_response(response, root_node = 'reportResponse')
      if response.xpath("//#{root_node}/responseCode").text != '0'
        reason = response.xpath("//#{root_node}/responseDescription").text
        raise InvalidRequest.new(reason)
      end
    end
  end
end
