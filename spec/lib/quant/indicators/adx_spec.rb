# frozen_string_literal: true

RSpec.describe Quant::Indicators::Adx do
  let(:apple_fixture_filename) { fixture_filename("AAPL-19990104_19990107.txt", :series) }
  let(:series) { Quant::Series.from_file(filename: apple_fixture_filename, symbol: "AAPL", interval: :daily) }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }

  context "ADX's periods matches ATR's" do
    it { expect(subject.traditional_period).to eq(subject.series.indicators[source].atr.traditional_period) }
    it { expect(subject.slow_period).to eq(subject.series.indicators[source].atr.slow_period) }
    it { expect(subject.full_period).to eq(subject.series.indicators[source].atr.full_period) }
  end

  context "sine series" do
    let(:period) { 40 }
    let(:cycles) { 4 }
    let(:uniq_data_points) { cycles * period / cycles } # sine is cyclical, so we expect a few unique data points
    let(:series) do
      # period bar sine wave
      Quant::Series.new(symbol: "SINE", interval: "1d").tap do |series|
        cycles.times do
          (0...period).each do |degree|
            radians = degree * 2 * Math::PI / period
            series << 5.0 * Math.sin(radians) + 10.0
          end
        end
      end
    end

    it { expect(subject.series.size).to eq(160) }

    it { expect(subject.values.last(5).map{ |v| v.dmu.round(4) }).to eq([0.5096, 0.5966, 0.669, 0.7249, 0.7629]) }
    it { expect(subject.values.last(5).map{ |v| v.dmd.round(4) }).to eq([0.5096, 0.5966, 0.669, 0.7249, 0.7629]) }

    it { expect(subject.values.last(5).map{ |v| v.value.round(4) }).to eq([0.3686, 0.3418, 0.2907, 0.2254, 0.1574]) }
    it { expect(subject.values.last(5).map{ |v| v.stoch.round(4) }).to eq([48.3063, 46.6152, 41.0631, 32.902, 23.7553]) }

    it { expect(subject.values.last(5).map{ |v| v.full.round(4) }).to eq([2.3542, 2.1598, 1.9475, 1.7248, 1.4983]) }
    it { expect(subject.values.last(5).map{ |v| v.slow.round(4) }).to eq([0.0245, 0.0245, 0.0246, 0.0248, 0.0251]) }
    it { expect(subject.values.last(5).map{ |v| v.traditional.round(4) }).to eq([0.3686, 0.3418, 0.2907, 0.2254, 0.1574]) }

    it "is roughly half and half" do
      direction_of_changes = subject.values.each_cons(2).map{ |(a, b)| a.value - b.value > 0 }
      value_counts = direction_of_changes.group_by(&:itself).transform_values(&:count)

      expect(value_counts[true].to_f / value_counts[false]).to be > 0.7
    end
  end
end
