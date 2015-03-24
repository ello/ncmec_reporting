require 'spec_helper'

describe NcmecReporting::FileInfo do

  it 'provides a simple XML accessor' do
    expect(described_class.new('xml').xml).to eq('xml')
  end

end
