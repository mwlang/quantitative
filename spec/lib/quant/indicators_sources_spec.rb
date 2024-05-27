# frozen_string_literal: true

RSpec.describe Quant::IndicatorsSources do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject[source]).to be_a Quant::IndicatorsSource }

  it "raises an error for an invalid source" do
    expect { subject[:invalid_source] }.to raise_error Quant::Errors::InvalidIndicatorSource
  end

  it "raises an error for a stringified valid source" do
    expect { subject["oc2"] }.to raise_error Quant::Errors::InvalidIndicatorSource
  end

  context 'oc2 as default source' do
    it { expect(subject[:oc2].ping.map(&:pong)).to eq [3.0, 6.0, 12.0, 24.0] }
    it { expect(subject.ping.map(&:pong)).to eq [3.0, 6.0, 12.0, 24.0] }
    it { expect(subject.ping.source).to eq :oc2 }
  end
end
