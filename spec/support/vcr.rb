VCR.configure do |c|
  c.cassette_library_dir = 'spec/support/fixtures/vcr_cassettes'
  c.hook_into :typhoeus
  c.filter_sensitive_data('<NCMEC_USERNAME>') { ENV['NCMEC_USERNAME'] }
  c.filter_sensitive_data('<NCMEC_PASSWORD>') { ENV['NCMEC_PASSWORD'] }
  c.filter_sensitive_data('<NCMEC_CREDS>') { Base64.strict_encode64("#{ENV['NCMEC_USERNAME']}:#{ENV['NCMEC_PASSWORD']}") }
  c.filter_sensitive_data('<NCMEC_ENDPOINT>') { ENV['NCMEC_ENDPOINT'] }
  c.filter_sensitive_data('<AWS_ACCESS_KEY_ID>') { ENV['AWS_ACCESS_KEY_ID'] }
  c.filter_sensitive_data('<AWS_SECRET_ACCESS_KEY>') { ENV['AWS_SECRET_ACCESS_KEY'] }
  c.filter_sensitive_data('<S3_ASSET_QUARANTINE_BUCKET>') { ENV['S3_ASSET_QUARANTINE_BUCKET'] }
  c.filter_sensitive_data('<S3_METADATA_QUARANTINE_BUCKET>') { ENV['S3_METADATA_QUARANTINE_BUCKET'] }
end
