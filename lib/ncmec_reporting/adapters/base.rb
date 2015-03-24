module NcmecReporting
  module Adapters

    autoload :S3, 'ncmec_reporting/adapters/s3'

    class Base

      def self.configure
        raise BadConfiguration, 'No configuration block provided' unless block_given?

        yield self
      end

      def initialize(report_id)
        raise ArgumentError.new('You must provide a report_id.') unless report_id

        @report_id = report_id
      end

      def store_text(filename, content)
        new_file = create_new_file(filename, content)

        add_to_tar(texts_tar, new_file)
      end

      def store_assets(files)
        files = [files] unless files.is_a?(Array)

        add_to_tar(assets_tar, files)

        files.each do |file|
          if file.fileinfo
            store_text("#{file.file_id}.xml", file.fileinfo.xml)
          end
        end
      end

      def upload(*)
        raise RuntimeError.new('#upload must be overridden in the adapter subclass')
      end

      private

      def create_new_file(filename, content)
        file_details = filename.split('.', 2)
        file_details[1] = '.' + file_details[1] if file_details[1]

        Tempfile.new(file_details).tap do |file|
          file.write(content)
          file.flush
        end
      end

      def texts_tar
        @texts_tar ||= create_tar
      end

      def assets_tar
        @assets_tar ||= create_tar
      end

      def create_tar
        Tempfile.new([@report_id, '.tar.gz'])
      end

      def add_to_tar(tar, files)
        files = [files] unless files.is_a?(Array)

        file_paths = files.map(&:path).join(' ')

        `tar -rvf #{tar.path} #{file_paths} 2>&1`
      end

      def final_tar_filename
        "report_#{@report_id}.tar.gz"
      end

    end
  end
end
