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
end
