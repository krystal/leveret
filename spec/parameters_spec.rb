require 'spec_helper'

describe Leveret::Parameters do
  let(:params) { Leveret::Parameters.new(:one => 1, 'two' => 'two', '3' => 'four') }

  describe '[]' do
    it 'can access a symbol entry with a symbol' do
      expect(params[:one]).to eq(1)
    end
    it 'can access a string entry with a string' do
      expect(params['two']).to eq('two')
    end
    it 'can access a string entry with a symbol' do
      expect(params[:two]).to eq('two')
    end
    it 'can access a symbol entry with a string' do
      expect(params['one']).to eq(1)
    end
    it 'returns nil when the key doesn\'t exist' do
      expect(params[:does_not_exist]).to be_nil
    end
  end

  describe '#serialize' do
    it 'encodes a hash into json' do
      hsh = { one: 1, two: 'two' }
      json = JSON.dump(hsh)

      expect(Leveret::Parameters.new(hsh).serialize).to eq(json)
    end
  end

  describe '.from_json' do
    it 'decodes JSON into parameters' do
      json = '{"one":1,"two":"two"}'
      hsh = JSON.load(json)
      params = Leveret::Parameters.new(hsh)

      expect(Leveret::Parameters.from_json(json)).to eq(params)
    end
  end
end
