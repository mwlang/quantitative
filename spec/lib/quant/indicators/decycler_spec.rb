# frozen_string_literal: true

RSpec.describe Quant::Indicators::Decycler do
  using Quant

  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
  it { expect(subject.values.map{ |v| v.hp1.round(3) }).to eq([0.0, 1.996, 4.518, 8.903]) }
  it { expect(subject.values.map{ |v| v.hp2.round(3) }).to eq([0.0, 2.588, 7.025, 15.32]) }
  it { expect(subject.values.map{ |v| v.osc.round(3) }).to eq([0.0, 0.591, 2.507, 6.417]) }
  it { expect(subject.values.map{ |v| v.peak.round(3) }).to eq([0.0, 0.591, 2.507, 6.417]) }
  it { expect(subject.values.map{ |v| v.agc.round(3) }).to eq([0.0, 1.0, 1.0, 1.0]) }

  context "sine series" do
    let(:source) { :oc2 }
    let(:period) { 40 }
    let(:cycles) { 5 }
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

    it { expect(subject.series.size).to eq(cycles * period) }

    it { expect(subject.values.last(5).map{ |v| v.agc.round(3) }).to eq([0.609, 0.757, 0.889, 1.0, 1.0]) }
    it { expect(subject.values.first(5).map{ |v| v.agc.round(3) }).to eq([0.0, 1.0, 1.0, 1.0, 1.0]) }
    it { expect(subject.values.map{ |v| v.agc.round(1) }.uniq).to eq([0.0, 1.0, 0.9, 0.7, 0.5, 0.3, 0.1, -0.2, -0.5, -0.7, -1.0, -0.9, -0.8, -0.4, 0.2, 0.8, 0.4, -0.1, -0.3, -0.6, 0.6]) }
    it { expect(subject.values.map{ |v| v.ift.round(1) }.uniq).to eq([0.0, 1.0, 0.9, 0.3, -0.8, -1.0, -0.1, 0.7, 0.8, -0.5, -0.9, -0.3, 0.5]) }
  end
end
