# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::IndicatorsProxy do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.indicators.keys).to eq([]) }
  it { expect(subject.dominant_cycle).to be_a(Quant::Indicators::DominantCycles::HalfPeriod) }
end
