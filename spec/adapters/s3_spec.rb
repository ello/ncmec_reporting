require 'spec_helper'

describe NcmecReporting::Adapters::S3 do

  subject { described_class.new('1234') }

  context 'without buckets created' do

    describe '#store_text' do

      it 'raises an error if it cannot find the bucket' do
        expect { subject.store_text(anything, anything, anything) }.to raise_error(NcmecReporting::NonexistentS3Bucket)
      end

    end

    describe '#store_assets' do

      it 'raises an error if it cannot find the bucket' do
        expect { subject.store_assets(anything, anything) }.to raise_error(NcmecReporting::NonexistentS3Bucket)
      end

    end

  end

  context 'with a bucket created' do

    def tar_dump(s3_file)
      tempfile = Tempfile.new(['uploaded_file', '.tar.gz'])
      tempfile.write(s3_file.body)
      tempfile.flush

      `tar -tvf #{tempfile.path}`
    end

    let(:asset_bucket) { subject.connection.directories.get(described_class.asset_bucket) }
    let(:text_bucket) { subject.connection.directories.get(described_class.text_bucket) }

    before do
      subject.connection.directories.create(key: described_class.text_bucket)
      subject.connection.directories.create(key: described_class.asset_bucket)
    end

    describe '#store_text' do

      let(:report) { NcmecReporting::XmlBuilder.create(:report) }

      it 'adds the text to a gunzipped tar file' do
        subject.store_text('report.xml', report)
        subject.store_text('file_1234.xml', '<xml>')
        subject.upload

        texts_tar = text_bucket.files.get('report_1234.tar.gz')

        files = tar_dump(texts_tar)

        expect(files).to match(/report.*\.xml$/)
        expect(files).to match(/file_1234.*\.xml$/)
      end

    end

    describe '#store_assets' do

      let(:meta) { NcmecReporting::XmlBuilder.create(:fileDetails) }
      let(:fileinfo) { NcmecReporting::FileInfo.new(meta) }

      let(:bad_image) { File.expand_path('../../support/fixtures/bad_image.jpg', __FILE__) }
      let(:very_bad_image) { File.expand_path('../../support/fixtures/very_bad_image.jpg', __FILE__) }
      let(:file1) { NcmecReporting::File.new(bad_image) }
      let(:file2) { NcmecReporting::File.new(very_bad_image, fileinfo) }

      before do
        file2.file_id = 'file_1234'
      end

      it 'adds the assets to a gunzipped tar file' do
        subject.store_assets([file1, file2])
        subject.upload

        assets_tar = asset_bucket.files.get('report_1234.tar.gz')
        texts_tar = text_bucket.files.get('report_1234.tar.gz')

        asset_files = tar_dump(assets_tar)

        expect(asset_files).to match(/bad_image.*\.jpg$/)
        expect(asset_files).to match(/very_bad_image.*\.jpg$/)

        text_files = tar_dump(texts_tar)

        expect(text_files).to match(/file_1234.*\.xml$/)
      end

    end

  end

end
