require 'ncmec_reporting'
require 'rspec'
require 'vcr'
require 'builder'

ENV['NCMEC_ENDPOINT'] = '***REMOVED***'
ENV['NCMEC_USERNAME'] = '***REMOVED***'
ENV['NCMEC_PASSWORD'] = '***REMOVED***'
ENV['AWS_ACCESS_KEY_ID'] = '***REMOVED***'
ENV['AWS_SECRET_ACCESS_KEY'] = '***REMOVED***'
ENV['S3_ASSET_QUARANTINE_BUCKET'] = '***REMOVED***'
ENV['S3_METADATA_QUARANTINE_BUCKET'] = '***REMOVED***'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.before(:each) do
    NcmecReporting.configure do |config|
      config.base_uri = ENV['NCMEC_ENDPOINT']
      config.username = ENV['NCMEC_USERNAME']
      config.password = ENV['NCMEC_PASSWORD']

      config.quarantine_adapter NcmecReporting::Adapters::S3 do |adapter|
        adapter.access_key_id = ENV['AWS_ACCESS_KEY_ID']
        adapter.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

        adapter.asset_bucket = ENV['S3_ASSET_QUARANTINE_BUCKET']
        adapter.text_bucket = ENV['S3_METADATA_QUARANTINE_BUCKET']
      end
    end
  end

  config.around(:each) do |config|
    options = config.metadata[:vcr] || {}
    if options[:record] == :skip
      VCR.turned_off(&config)
    else
      name = config.metadata[:full_description].split(/\s+/, 2).join('/').gsub(' ', '_').gsub(/[^\w\/]+/, '_')
      VCR.use_cassette(name, options, &config)
    end
  end

  config.before(:each) do
    Fog.mock!
    Fog::Mock.reset
  end

  config.include NcmecReporting::APIStub::Helpers
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/support/fixtures/vcr_cassettes'
  c.hook_into :typhoeus
end
