require 'uri'

module NcmecReporting
  class API
    def status
      get('/status')
    end

    def submit(report)
      xml_post('/submit', report.to_s)
    end

    def upload(report_id, file)
      Configuration.logger.info "[NCMEC] [REPORT #{report_id}] Uploading file"

      post('/upload', {
        id: report_id,
        file: file
      })
    end

    def fileinfo(metadata)
      xml_post('/fileinfo', metadata.to_s)
    end

    def finish(report_id)
      post('/finish', id: report_id)
    end

    def retract(report_id)
      post('/retract', id: report_id)
    end

    private

    def base_connection
      Faraday.new(url: Configuration.base_uri) do |faraday|
        faraday.request  :basic_auth, Configuration.username, Configuration.password
        faraday.adapter  :typhoeus
      end
    end

    def build_url(url)
      uri = URI(Configuration.base_uri)
      uri.path + url
    end

    def encoded_connection
      base_connection.tap do |conn|
        conn.request :url_encoded
      end
    end

    def multipart_connection
      base_connection.tap do |conn|
        conn.request :multipart
      end
    end

    def xml_connection
      multipart_connection.tap do |conn|
        conn.headers['Content-Type'] = 'text/xml; charset=utf-8'
      end
    end

    def get(url)
      parse(encoded_connection.get(build_url(url)).body)
    end

    def post(url, body)
      parse(multipart_connection.post(build_url(url), body).body)
    end

    def xml_post(url, body)
      parse(xml_connection.post(build_url(url), body).body)
    end

    def parse(doc)
      Nokogiri::XML(doc)
    end
  end
end
