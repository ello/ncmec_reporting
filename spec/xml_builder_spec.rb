require 'spec_helper'

describe NcmecReporting::XmlBuilder do

  describe '.create' do

    it 'is a helper method to create a new builder' do
      expect_any_instance_of(described_class).to receive(:create)

      described_class.create(:anything)
    end

  end

  describe '#initialize' do

    it 'accepts a block, which receives an XML builder' do
      xml_builder = nil

      described_class.new do |builder|
        builder.anything
        xml_builder = builder
      end

      expect(xml_builder.to_s).to include('<anything/>')
    end

  end

  describe '#create' do

    subject { described_class.new }

    it 'creates some XML for a report submission' do
      expected_xml = <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <report xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="https://report.cybertip.org/ispws/xsd">
          <id>5</id>
        </report>
      XML

      xml = subject.create(:report) do |details|
        details.id 5
      end

      xml          = xml.gsub(/\n/, '').gsub(/\s/, '')
      expected_xml = xml.gsub(/\n/, '').gsub(/\s/, '')
      expect(xml).to eq(expected_xml)
    end

    it 'accepts optional attributes for the root node' do
      expected_xml = <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <report xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="https://report.cybertip.org/ispws/xsd"
        whatever="yes">
          <id>5</id>
        </report>
      XML

      xml = subject.create(:report, whatever: "yes") do |details|
        details.id 5
      end

      xml          = xml.gsub(/\n/, '').gsub(/\s/, '')
      expected_xml = xml.gsub(/\n/, '').gsub(/\s/, '')
      expect(xml).to eq(expected_xml)
    end

  end

end
