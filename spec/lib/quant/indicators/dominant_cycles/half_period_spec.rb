# frozen_string_literal: true

RSpec.describe Quant::Indicators::DominantCycles::HalfPeriod do
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
    let(:cycles) { 2 }
    let(:series) { sine_series(period:, cycles:) }

    it { expect(subject.series.size).to eq(period * cycles) }
    it { expect(subject.p0.period).to eq 29 }

    context "with an alternate configuration" do
      before do
        Quant.configure_indicators(max_period: 10, min_period: 4)
      end

      after(:all) { Quant.default_configuration! }

      it { expect(subject.p0.period).to eq 7 }
    end
  end
end
