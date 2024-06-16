# frozen_string_literal: true

RSpec.describe Quant::Indicators::DominantCycles::BandPass do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks.size).to eq(4) }
  it { expect(subject.p0).to eq subject.values[-1] }
  it { expect(subject.t0).to eq subject.ticks[-1] }

  context "sine series" do
    let(:period) { 40 }
    let(:cycles) { 3 }
    let(:series) { sine_series(period: 40, cycles: 3) }

    it { expect(subject.series.size).to eq(period * cycles) }
    it { expect(subject.p0.period).to eq 40 }
  end
end
