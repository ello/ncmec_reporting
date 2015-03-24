require 'spec_helper'

describe NcmecReporting::Submission::State do

  subject { described_class.new }

  describe 'state machine' do

    context 'from none' do
      it 'transitions to submit' do
        expect(subject.may_submit?).to eq(true)

        expect(subject.may_upload?).to eq(false)
        expect(subject.may_finish?).to eq(false)
        expect(subject.may_retract?).to eq(false)
      end
    end

    context 'from submit' do
      before { subject.submit }

      it 'transitions to upload, finish and retract' do
        expect(subject.may_upload?).to eq(true)
        expect(subject.may_finish?).to eq(true)
        expect(subject.may_retract?).to eq(true)

        expect(subject.may_submit?).to eq(false)
      end
    end

    context 'from finish' do
      before do
        report = subject.submit
        subject.finish
      end

      it 'transitions to nothing' do
        expect(subject.may_submit?).to eq(false)
        expect(subject.may_upload?).to eq(false)
        expect(subject.may_finish?).to eq(false)
        expect(subject.may_retract?).to eq(false)
      end
    end

    context 'from retract' do
      before do
        report = subject.submit
        subject.retract
      end

      it 'transitions to nothing' do
        expect(subject.may_submit?).to eq(false)
        expect(subject.may_upload?).to eq(false)
        expect(subject.may_finish?).to eq(false)
        expect(subject.may_retract?).to eq(false)
      end
    end

  end

end
