require "spec_helper"

RSpec.describe Quant::Indicators::Mesa do
  let(:apple_fixture_filename) { fixture_filename("AAPL-19990104_19990107.txt", :series) }
  let(:series) { Quant::Series.from_file(filename: apple_fixture_filename, symbol: "AAPL", interval: :daily) }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.values.map{ |v| v.mama.round(3) }).to eq([0.372, 0.376, 0.379, 0.384]) }
  it { expect(subject.values.map{ |v| v.lama.round(3) }).to eq([0.372, 0.372, 0.373, 0.373]) }
  it { expect(subject.values.map{ |v| v.osc.round(3) }).to eq([0.0, 0.003, 0.005, 0.007]) }
  it { expect(subject.values.map{ |v| v.stoch.round(3) }).to eq([0.0, 0.819, 2.922, 6.502]) }
  it { expect(subject.values.map(&:osc_up)).to all be(true) }

  context "sine series" do
    let(:cycles) { 4 }
    let(:uniq_data_points) { cycles * 40 / (cycles - 1) } # sine is cyclical, so we expect a few unique data points
    let(:series) do
      # 40 bar sine wave
      Quant::Series.new(symbol: "SINE", interval: "1d").tap do |series|
        cycles.times do
          (0..39).each do |degree|
            radians = degree * 2 * Math::PI / 40
            series << 5.0 * Math.sin(radians) + 10.0
          end
        end
      end
    end

    it { expect(subject.series.size).to eq(160) }
    it { expect(subject.values.map{ |m| m.mama.round(1) }.uniq.size).to be_within(5).of(uniq_data_points) }
  end
end
