module NcmecReporting
  module Adapters
    class S3 < Base

      class << self
        attr_accessor :access_key_id, :secret_access_key, :text_bucket, :asset_bucket
      end

      def store_text(*)
        validate_bucket_exists(texts_directory)

        super
      end

      def store_assets(*)
        validate_bucket_exists(assets_directory)

        super
      end

      def upload
        if @texts_tar
          texts_directory.files.create(key: final_tar_filename, body: @texts_tar)
        end

        if @assets_tar
          assets_directory.files.create(key: final_tar_filename, body: @assets_tar)
        end
      end

      def connection
        @connection ||= Fog::Storage.new(connection_config)
      end

      private

      def connection_config
        {
          provider: 'AWS',
          aws_access_key_id: self.class.access_key_id,
          aws_secret_access_key: self.class.secret_access_key
        }
      end

      def texts_directory
        @texts_directory ||= connection.directories.get(self.class.text_bucket)
      end

      def assets_directory
        @assets_directory ||= connection.directories.get(self.class.asset_bucket)
      end

      def validate_bucket_exists(bucket)
        unless bucket
          raise NonexistentS3Bucket.new('Could not find your S3 bucket. You must manually create your buckets with expiration configured')
        end
      end

    end
  end
end
