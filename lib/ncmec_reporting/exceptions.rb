module NcmecReporting
  class BadConfiguration < ArgumentError; end

  # We assume the bucket exists, since Fog doesn't seem to
  # have support for adjusting the bucket lifecycle.
  # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/S3/BucketLifecycleConfiguration.html
  class NonexistentS3Bucket < RuntimeError; end

  class InvalidReport < ArgumentError; end

  class InvalidRequest < ArgumentError; end
end
