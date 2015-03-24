module NcmecReporting
  class FileInfo
    attr_reader :xml

    def initialize(xml)
      @xml = xml
    end
  end
end
