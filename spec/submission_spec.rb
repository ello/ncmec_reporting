require 'spec_helper'

describe NcmecReporting::Submission do

  ID_REGEX = /[A-Za-z0-9]+/

  let(:report) do
    NcmecReporting::XmlBuilder.create(:report) do |report|
      report.incidentSummary do |summary|
        summary.incidentType described_class::PORN
        summary.incidentDateTime '2012-10-15T09:00:00-06:00'
      end

      report.reporter do |reporter|
        reporter.reportingPerson do |person|
          person.firstName 'Test'
          person.lastName 'User'
          person.email 'test@ello.co'
        end
      end
    end
  end

  let(:subject_with_stub) { described_class.new(NcmecReporting::APIStub.new) }

  before do
    allow_any_instance_of(NcmecReporting::Adapters::S3).to receive(:store_text)
    allow_any_instance_of(NcmecReporting::Adapters::S3).to receive(:store_assets)
  end

  describe '#create' do

    it 'submits the report and returns a report id' do
      report_id = subject.submit(report)

      expect(report_id).to match(/^#{ID_REGEX}$/)
    end

    it 'archives the report on a permanent storage (S3)' do
      expect_any_instance_of(NcmecReporting::Adapters::S3).to receive(:store_text).with('report.xml', report)

      subject.submit(report)
    end

    it 'calls the API with the supplied XML' do
      expect_any_instance_of(NcmecReporting::API).to receive(:submit).with(report).and_call_original

      subject.submit(report)
    end

    it 'errors without a incidentSummary with incidentType and incidentDateTime' do
      bad_report = report.gsub(/<incidentSummary>.*<\/incidentSummary>/m, '')
      expect { described_class.new.submit(bad_report) }.to raise_error(NcmecReporting::InvalidReport)

      bad_report = report.gsub(/<incidentDateTime>.*<\/incidentDateTime>/m, '')
      expect { described_class.new.submit(bad_report) }.to raise_error(NcmecReporting::InvalidReport)

      bad_report = report.gsub(/<incidentSummary>.*<\/incidentSummary>/m, '')
      expect { described_class.new.submit(bad_report) }.to raise_error(NcmecReporting::InvalidReport)
    end

    it 'errors without a reporter with reportingPerson' do
      bad_report = report.gsub(/<reportingPerson>.*<\/reportingPerson>/m, '')
      expect { described_class.new.submit(bad_report) }.to raise_error(NcmecReporting::InvalidReport)

      bad_report = report.gsub(/<reporter>.*<\/reporter>/m, '')
      expect { described_class.new.submit(bad_report) }.to raise_error(NcmecReporting::InvalidReport)
    end

    it 'errors if the report is seemingly valid but the server disagrees' do
      with_api_stub_flag(:invalid_submit) do
        expect { subject_with_stub.submit(report) }.to raise_error(NcmecReporting::InvalidRequest, 'You did it all wrong.')
      end
    end
  end

  describe '#upload' do

    it 'errors if the submission has not been created' do
      expect { subject.upload(anything) }.to raise_error(AASM::InvalidTransition)
    end

    context 'after creating a submission' do

      let(:bad_image) { File.expand_path('../support/fixtures/bad_image.jpg', __FILE__) }
      let(:file) { NcmecReporting::File.new(bad_image) }

      before do
        @report_id = subject.submit(report)
        subject_with_stub.submit(report)
      end

      it 'uploads a file and returns a file id' do
        expect_any_instance_of(NcmecReporting::API).to receive(:upload).with(@report_id, file).and_call_original
        expect_any_instance_of(NcmecReporting::API).not_to receive(:fileinfo)

        expect(subject.upload(file)).to match(/^#{ID_REGEX}$/)
      end

      it 'sets the file id on the file object after its been created' do
        subject.upload(file)

        expect(file.file_id).to match(/^#{ID_REGEX}$/)
      end

      it 'archives the file on a permanent storage (S3)' do
        expect_any_instance_of(NcmecReporting::Adapters::S3).to receive(:store_assets).with(file)

        subject.upload(file)
      end

      it 'can be called multiple times' do
        expect_any_instance_of(NcmecReporting::API).to receive(:upload).twice.and_call_original

        subject.upload(file)
        subject.upload(file)
      end

      it 'errors if the server throws an error' do
        with_api_stub_flag(:invalid_upload) do
          expect { subject_with_stub.upload(file) }.to raise_error(NcmecReporting::InvalidRequest, 'You did it all wrong.')
        end
      end

      context 'with metadata' do

        let(:metadata) do
          NcmecReporting::XmlBuilder.create(:fileDetails) do |details|
            details.details do |details|
              details.nameValuePair do |pair|
                pair.name 'Got details'
                pair.value 'Here they are'
              end

              details.nameValuePair do |pair|
                pair.name 'Got more details'
                pair.value 'Here they all are'
              end
            end
          end
        end

        let(:fileinfo) { NcmecReporting::FileInfo.new(metadata) }
        let(:file) { NcmecReporting::File.new(bad_image, fileinfo) }

        it 'adds the repord id and file id to the metadata and calls the API' do
          expect_any_instance_of(NcmecReporting::API).to receive(:fileinfo) do |_, metadata|
            expect(metadata).to match(/<reportId>#{ID_REGEX}<\/reportId>/)
            expect(metadata).to match(/<fileId>#{ID_REGEX}<\/fileId>/)
          end.and_return(NcmecReporting::APIStub.new.fileinfo)

          subject.upload(file)
        end

        it 'still returns the file id' do
          expect(subject.upload(file)).to match(/^#{ID_REGEX}$/)
        end

        it 'errors if the server throws an error' do
          with_api_stub_flag(:invalid_fileinfo) do
            expect { subject_with_stub.upload(file) }.to raise_error(NcmecReporting::InvalidRequest, 'You did it all wrong.')
          end
        end
      end
    end
  end

  describe '#finish' do

    it 'errors if the submission has not been created' do
      expect { subject.finish }.to raise_error(AASM::InvalidTransition)
    end

    context 'after creating a submission' do

      before do
        @report_id = subject.submit(report)
        subject_with_stub.submit(report)
      end

      it 'calls the API to finish the report' do
        expect_any_instance_of(NcmecReporting::API).to receive(:finish).with(@report_id).and_call_original

        subject.finish
      end

      it 'uploads the files to the archive' do
        expect_any_instance_of(NcmecReporting::Adapters::S3).to receive(:upload)

        subject.finish
      end

      it 'can only be called once' do
        subject.finish
        expect { subject.finish }.to raise_error(AASM::InvalidTransition)
      end

      it 'errors if the server throws an error' do
        with_api_stub_flag(:invalid_finish) do
          expect { subject_with_stub.finish }.to raise_error(NcmecReporting::InvalidRequest, 'You did it all wrong.')
        end
      end

      context 'after retracting the submission' do
        before do
          subject.retract
        end

        it 'errors' do
          expect { subject.finish }.to raise_error(AASM::InvalidTransition)
        end
      end
    end
  end

  describe '#retract' do

    it 'errors if the submission has not been created' do
      expect { subject.retract }.to raise_error(AASM::InvalidTransition)
    end

    context 'after creating a submission' do

      before do
        @report_id = subject.submit(report)
        subject_with_stub.submit(report)
      end

      it 'calls the API to retract the report' do
        expect_any_instance_of(NcmecReporting::API).to receive(:retract).with(@report_id).and_call_original

        subject.retract
      end

      it 'can only be called once' do
        subject.retract
        expect { subject.retract }.to raise_error(AASM::InvalidTransition)
      end

      it 'errors if the server throws an error' do
        with_api_stub_flag(:invalid_retract) do
          expect { subject_with_stub.retract }.to raise_error(NcmecReporting::InvalidRequest, 'You did it all wrong.')
        end
      end

      context 'after finishing the submission' do
        before do
          subject.finish
        end

        it 'errors' do
          expect { subject.retract }.to raise_error(AASM::InvalidTransition)
        end
      end
    end
  end
end
