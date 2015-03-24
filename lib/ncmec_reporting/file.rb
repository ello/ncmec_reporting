module NcmecReporting
  class File < ::File
    attr_reader :fileinfo
    attr_accessor :file_id

    def self.from_file(file, *args)
      new(file.path, *args)
    end

    def initialize(filename, fileinfo = nil)
      @fileinfo = fileinfo

      super(filename, 'r')
    end
  end
end
