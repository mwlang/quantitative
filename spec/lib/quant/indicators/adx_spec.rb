require "spec_helper"

RSpec.describe Quant::Indicators::Adx do
  let(:apple_fixture_filename) { fixture_filename("AAPL-19990104_19990107.txt", :series) }
  let(:series) { Quant::Series.from_file(filename: apple_fixture_filename, symbol: "AAPL", interval: :daily) }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }

  context "sine series" do
    let(:period) { 40 }
    let(:cycles) { 4 }
    let(:uniq_data_points) { cycles * 40 / cycles } # sine is cyclical, so we expect a few unique data points
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

    it { expect(subject.values.last(5).map{ |v| v.diu.round(4) }).to eq([1.6077, 15.8702, 29.1715, 38.7976, 45.3035]) }
    it { expect(subject.values.last(5).map{ |v| v.did.round(4) }).to eq([1.6077, 15.8702, 29.1715, 38.7976, 45.3035]) }

    it { expect(subject.values.last(5).map{ |v| v.di.round(4) }).to eq([3.186, 0.4493, 0.228, 0.1241, 0.0718]) }

    it "is roughly half and half" do
      direction_of_changes = subject.values.each_cons(2).map{ |(a, b)| a.value - b.value > 0 }
      value_counts = direction_of_changes.group_by(&:itself).transform_values(&:count)

      expect(value_counts[true].to_f / value_counts[false]).to be > 0.8
    end
  end
end
