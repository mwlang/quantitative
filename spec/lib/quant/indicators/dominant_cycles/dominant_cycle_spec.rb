# frozen_string_literal: true

RSpec.describe Quant::Indicators::DominantCycles::DominantCycle do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }
  let(:test_class) do
    Class.new(described_class) do
      def compute_period
        p0.period = 10
      end
    end
  end

  subject { test_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks.size).to eq(4) }
  it { expect(subject.p0).to eq subject.values[-1] }
  it { expect(subject.t0).to eq subject.ticks[-1] }
end
