# NCMEC Reporting

This gem aids in reporting incidents to [NCMEC](http://www.missingkids.com/), an organization designed to promote a safer internet for children.

Reports are composed of a number of pieces:
- The report XML data itself, outlining characteristics of an incident.
- Media that was uploaded to an application.
- Metadata about the media that was uploaded.

This gem provides an API wrapper to upload the above information to NCMEC through a simple Ruby interface. An imperative step in reporting incidents is the quarantining of the above report information. NCMEC keeps a copy of the report data, but this report data must be removed from the application and placed in a secure location in case it needs to be referenced in the future. Report and metadata XML must be stored indefinitely, and media must expire after a 90 day period.

## Example

Let's walk through how to use this gem to report an incident to NCMEC. Take a look at the [full example](#full-example) below for a comprehensive look at how the following steps come together.

### Configuration

Start by configuring the gem in an initializer. Currently, only S3 is supported as the quarantining store.

```ruby
NcmecReporting.configure do |config|
  config.username = ENV['NCMEC_USERNAME']
  config.password = ENV['NCMEC_PASSWORD']

  config.quarantine_adapter NcmecReporting::Adapters::S3 do |adapter|
    adapter.access_key_id = ENV['AWS_ACCESS_KEY_ID']
    adapter.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

    adapter.asset_bucket = ENV['S3_ASSET_QUARANTINE_BUCKET']
    adapter.text_bucket = ENV['S3_METADATA_QUARANTINE_BUCKET']
  end
end
```

In development and staging, you can configure this gem to use the test NCMEC API endpoint by setting the `base_uri` configuration variable:

```ruby
NcmecReporting.configure do |config|
  config.base_uri = 'https://exttest.cybertip.org/ispws'
end
```

By default, your logs will only show details about the request/response URLs and response codes. You can configure a logger if you'd like to see details pertinent to debugging:

```ruby
NcmecReporting.configure do |config|
  config.logger = Rails.logger
end
```

Loggers should respond to `#debug`, `#info`, `#warn`, `#error`, `#fatal`.

### Build report

There are two primary pieces of data that can be submitted to NCMEC as XML: the initial report and file metadata. Let's look at building the initial report, building the file metadata is addressed later.

To keep the library small and flexible, you must build your XML by hand. This library does not provide an abstraction on the XML documents themselves, but provides some conveniences. To build your XML, we recommend using [builder](https://github.com/jimweirich/builder) which is automatically available to you. Let's create a report:

```ruby
report = NcmecReporting::XmlBuilder.create(:report) do |report|
  report.incidentSummary do |summary|
    summary.incidentType NcmecReporting::Submission::PORN
    summary.incidentDateTime '2015-01-01T09:00:00-06:00'
  end

  report.reporter do |reporter|
    reporter.reportingPerson do |person|
      person.firstName 'Test'
      person.lastName 'User'
    end
  end
end
```

The report data is arbitrary, but `NcmecReporting::XmlBuilder.create(:report)` will clean up the redundancy of generating these XML documents. Refer to the NCMEC API spec to determine what fields are possible.

The main integration point with this gem is the `Submission` class. With the report XML built above, we can create a submission:

```ruby
submission = NcmecReporting::Submission.new
```

Now, we must submit the XML report to start the submission process. Nothing can be done until this step is complete:

```ruby
report_id = submission.submit(report)
```

This makes an API request to NCMEC and returns the newly created report id.

### Uploading files

Now that the report is submitted, you can attach files to the submission. It's assumed that you have the file downloaded and stored into a file accessible on your server's file system. You must convert your file into a `NcmecReporting::File`:

You can create the `NcmecReporting::File` from a path:

```ruby
file = NcmecReporting::File.new('/tmp/my-file.jpg')
```

Or you can create it from an existing file:

```ruby
raw_file = File.new('/tmp/my-file.jpg')
file = NcmecReporting::File.from_file(raw_file)
```

Once you've created a file, add it to the submission:

```ruby
submission.upload(file)
```

This makes an API request to NCMEC and associates the file to the report created previously.

If you'd like to attach optional metadata to a file, create your metadata XML, using `NcmecReporting::XmlBuilder` if you'd like. This metadata should include any information that was stripped from the original file, like GPS coordinates. This library will automatically add the report and file id to the metadata:

```ruby
metadata = NcmecReporting::XmlBuilder.create(:fileDetails) do |details|
  details.details do |details|
    details.nameValuePair do |pair|
      pair.name 'GPS Altitude'
      pair.value '30.3 m Above Sea Level'
    end

    details.nameValuePair do |pair|
      pair.name 'GPS Position'
      pair.value '38.806500000 N, 77.052166667 W'
    end
  end
end
```

When uploading metadata, attach the metadata to the file before uploading:

```ruby
fileinfo = NcmecReporting::FileInfo.new(metadata)
file = NcmecReporting::File.new('/tmp/my-file.jpg', fileinfo)
```

Notice the second argument to `NcmecReporting::File.new`.

The `FileInfo` and `File` classes are separate entities in case at any point, someone wanted to upload only metadata, without needing to also reupload a file (maybe fixing an error).

Now, upload the file in the same way as uploading a file without metadata:

```ruby
submission.upload(file)
```

You may upload as many files (with or without metadata) as many times as you'd like. They are individually submitted to NCMEC.

### Finishing the report

Once you've finished generating the report and uploading files, you can finish the report:

```ruby
submission.finish
```

This indicates you have now finished creating your NCMEC report. No futher action can be taken on this object. Prior to calling `#finish`, no data had been quarantined. Calling `#finish` will quarantine the data on your servers after it has been successfully finished via NCMEC.

Any textual data, like the initial report XML and any file metadata, will be tar gunzipped into a single file, and placed on your configured server with the file name as the report id generated:

```
text-quarantine/report_1234.tar.gz
```

Any media that has been uploaded will also be tar gunzipped into a single file:

```
asset-quarantine/report_1234.tar.gz
```

### Retracting the report

In some cases, you can decide not to submit a report:

```ruby
submission.retract
```

This indicates you would like to remove the report from NCMEC and would not like to quarantine any data on your servers. No futher action can be taken on this object. If you do not call `#finish` or `#retract`, the report will not be quarantined and NCMEC will automatically delete the report after 24 hours.


### Full Example

Here is a full example of submitting a report:

```ruby
NcmecReporting.configure do |config|
  config.username = ENV['NCMEC_USERNAME']
  config.password = ENV['NCMEC_PASSWORD']

  config.quarantine_adapter NcmecReporting::Adapters::S3 do |adapter|
    adapter.access_key_id = ENV['AWS_ACCESS_KEY_ID']
    adapter.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

    adapter.asset_bucket = ENV['S3_ASSET_QUARANTINE_BUCKET']
    adapter.text_bucket = ENV['S3_METADATA_QUARANTINE_BUCKET']
  end
end

report = NcmecReporting::XmlBuilder.create(:report) do |report|
  report.incidentSummary do |summary|
    summary.incidentType NcmecReporting::Submission::PORN
    summary.incidentDateTime '2015-01-01T09:00:00-06:00'
  end

  report.reporter do |reporter|
    reporter.reportingPerson do |person|
      person.firstName 'Test'
      person.lastName 'User'
    end
  end
end

submission = NcmecReporting::Submission.new

submission.submit(report)

metadata = NcmecReporting::XmlBuilder.create(:fileDetails) do |details|
  details.details do |details|
    details.nameValuePair do |pair|
      pair.name 'GPS Altitude'
      pair.value '30.3 m Above Sea Level'
    end

    details.nameValuePair do |pair|
      pair.name 'GPS Position'
      pair.value '38.806500000 N, 77.052166667 W'
    end
  end
end

fileinfo = NcmecReporting::FileInfo.new(metadata)
file = NcmecReporting::File.new('/tmp/my-file.jpg', fileinfo)

submission.upload(file)

submission.finish
```