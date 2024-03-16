require "spec_helper"

RSpec.describe Quant::Indicators::Mama do
  let(:apple_fixture_filename) { fixture_filename("AAPL-19990104_19990107.txt", :series) }
  let(:series) { Quant::Series.from_file(filename: apple_fixture_filename, symbol: "AAPL", interval: :daily) }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.values.map{ |v| v.mama.round(3) }).to eq([0.372, 0.375, 0.378, 0.382]) }
  it { expect(subject.values.map{ |v| v.fama.round(3) }).to eq([0.372, 0.373, 0.374, 0.375]) }
  it { expect(subject.values.map{ |v| v.gama.round(3) }).to eq([0.372, 0.373, 0.375, 0.377]) }
  it { expect(subject.values.map{ |v| v.dama.round(3) }).to eq([0.372, 0.372, 0.373, 0.373]) }
  it { expect(subject.values.map{ |v| v.lama.round(3) }).to eq([0.372, 0.372, 0.372, 0.373]) }
  it { expect(subject.values.map{ |v| v.faga.round(3) }).to eq([0.372, 0.372, 0.372, 0.372]) }
  it { expect(subject.values.map{ |v| v.osc.round(3) }).to eq([0.0, 0.002, 0.004, 0.007]) }
  it { expect(subject.values.map(&:crossed)).to all be(:unchanged) }

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
    it { expect(subject.values.map{ |m| m.mama.round(1) }.uniq.size).to be_within(10).of(uniq_data_points) }

    it "crosses 2x cycles" do
      grouped_crossings = subject.values.map(&:crossed).group_by(&:itself).transform_values{|v| v.count}
      unchanged_count = period * cycles - cycles * 2
      expect(grouped_crossings).to eq({ down: cycles, unchanged: unchanged_count, up: cycles })
    end
  end
end
