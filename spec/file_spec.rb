require 'spec_helper'

describe NcmecReporting::File do

  let(:filepath) { Tempfile.new('anything.jpg').path }
  let(:fileinfo) { NcmecReporting::FileInfo.new('<xml>') }

  it 'is a subclass of File' do
    expect(described_class).to be < File
  end

  it 'accepts fileinfo as an argument to .new' do
    file = described_class.new(filepath, fileinfo)

    expect(file.fileinfo).to eq(fileinfo)
  end

  it 'allows setting the file id after it has been created' do
    file = described_class.new(filepath)

    expect(file.file_id).to be_nil

    file.file_id = 'file_1234'

    expect(file.file_id).to eq('file_1234')
  end

  describe '.from_file' do

    it 'creates a new NcmecReporting::File from a normal file, with optional fileinfo' do
      raw_file = File.new(filepath)

      file = described_class.from_file(raw_file, fileinfo)

      expect(file.fileinfo).to eq(fileinfo)
    end

  end

end
