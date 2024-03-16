require "spec_helper"

RSpec.describe Quant::Indicators::Atr do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.values.map{ |v| v.tr.round(3) }).to eq([0.0, 4.0, 8.0, 16.0]) }
  it { expect(subject.values.map{ |v| v.value.round(3) }).to eq([0.0, 0.231, 0.95, 2.57]) }
  # it { expect(subject.values.map(&:crossed)).to all be(:unchanged) }

  context "sine series" do
    let(:period) { 40 } # period bar sine wave
    let(:cycles) { 4 }
    let(:series) do
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
    it { expect(subject.values.last(5).map{ |v| v.value.round(3) }).to eq([0.179, 0.237, 0.321, 0.419, 0.52]) }

    it "crosses 4x cycles" do
      grouped_crossings = subject.values.map(&:crossed).group_by(&:itself).transform_values{|v| v.count}
      unchanged_count = period * cycles - cycles * 4
      expect(grouped_crossings).to eq({ down: cycles * 2, unchanged: unchanged_count, up: cycles * 2 })
    end
  end
end
