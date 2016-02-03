require 'ncmec_reporting'
require 'rspec'
require 'vcr'
require 'builder'
require 'pry'
require 'dotenv'

Dotenv.load

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.before(:each) do
    NcmecReporting.configure do |c|
      c.base_uri = ENV['NCMEC_ENDPOINT']
      c.username = ENV['NCMEC_USERNAME']
      c.password = ENV['NCMEC_PASSWORD']

      c.quarantine_adapter NcmecReporting::Adapters::S3 do |adapter|
        adapter.access_key_id = ENV['AWS_ACCESS_KEY_ID']
        adapter.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

        adapter.asset_bucket = ENV['S3_ASSET_QUARANTINE_BUCKET']
        adapter.text_bucket = ENV['S3_METADATA_QUARANTINE_BUCKET']
      end
    end
  end

  config.around(:each) do |c|
    options = c.metadata[:vcr] || {}
    if options[:record] == :skip
      VCR.turned_off(&c)
    else
      name = c.metadata[:full_description].split(/\s+/, 2).join('/').gsub(' ', '_').gsub(/[^\w\/]+/, '_')
      VCR.use_cassette(name, options, &c)
    end
  end

  config.before(:each) do
    Fog.mock!
    Fog::Mock.reset
  end

  config.include NcmecReporting::APIStub::Helpers
end
