module NcmecReporting

  autoload :Adapters, 'ncmec_reporting/adapters/base'

  class Configuration

    class << self
      attr_accessor :username, :password, :base_uri, :logger
    end

    self.base_uri = 'https://report.cybertip.org/ispws/status'
    self.logger = NcmecReporting::NullLogger.new

    def self.quarantine_adapter(type = NcmecReporting::Adapters::S3, &block)
      if block_given?
        type.configure(&block)
        @adapter = type
      else
        @adapter
      end
    end

  end

  def self.configure
    yield Configuration
  end
end
