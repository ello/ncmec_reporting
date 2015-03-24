require 'spec_helper'

describe NcmecReporting::Status do

  describe '#online?' do

    it 'returns true if it can connect to the server and authenticate' do
      expect(described_class.new.online?).to eq(true)
    end

    it 'returns false if it cannot connect to the server and authenticate' do
      NcmecReporting.configure do |config|
        config.username = 'badusername'
        config.password = 'badpassword'
      end

      expect(described_class.new.online?).to eq(false)
    end

  end

end
