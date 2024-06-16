# frozen_string_literal: true

RSpec.describe Quant::Indicators::Atr do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.values.map{ |v| v.tr.round(3) }).to eq([2.0, 4.0, 8.0, 16.0]) }
  it { expect(subject.values.map{ |v| v.value.round(3) }).to eq([0.115, 0.34, 1.045, 2.646]) }

  context "sine series" do
    let(:period) { 40 } # period bar sine wave
    let(:cycles) { 4 }
    let(:series) { sine_series(period:, cycles:) }

    it { expect(subject.series.size).to eq(160) }

    # NOTE: Traditional same as adaptive values in  test suite due to setting to static HalfPerod Indicator
    it { expect(subject.values.last(5).map{ |v| v.traditional.round(3) }).to eq([0.179, 0.237, 0.321, 0.419, 0.52]) }
    it { expect(subject.values.last(5).map{ |v| v.value.round(3) }).to eq([0.179, 0.237, 0.321, 0.419, 0.52]) }

    it { expect(subject.values.last(5).map{ |v| v.full.round(3) }).to eq([0.471, 0.441, 0.418, 0.403, 0.397]) }
    it { expect(subject.values.last(5).map{ |v| v.slow.round(3) }).to eq([0.507, 0.503, 0.499, 0.495, 0.491]) }

    it "crosses 4x cycles for adaptive value" do
      grouped_crossings = subject.values.map(&:crossed).group_by(&:itself).transform_values(&:count)
      unchanged_count = period * cycles - cycles * 4
      expect(grouped_crossings).to eq({ down: cycles * 2, unchanged: unchanged_count, up: cycles * 2 })
    end
  end
end
