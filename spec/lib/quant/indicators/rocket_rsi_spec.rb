# frozen_string_literal: true

RSpec.describe Quant::Indicators::RocketRsi do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
  it { expect(subject.values.map{ |v| v.rsi.round(3) }).to eq([0.0, 1.0, 1.0, 1.0]) }

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

    context "when price is climbing" do
      it { expect(subject.values[-10, 5].map{ |v| v.input.round(3) }).to eq([5.0, 5.062, 5.245, 5.545, 5.955]) }
      it { expect(subject.values[-10, 5].map{ |v| v.rsi.round(3) }).to eq([-1.0, -1.0, -1.0, -1.0, -1.0]) }
      it { expect(subject.values[-5, 5].map{ |v| v.input.round(3) }).to eq([6.464, 7.061, 7.73, 8.455, 9.218]) }
      it { expect(subject.values[-5, 5].map{ |v| v.rsi.round(3) }).to eq([-1.0, -1.0, -1.0, -1.0, -1.0]) }
    end

    context "when price is in valley" do
      it { expect(subject.values[-12, 5].map{ |v| v.input.round(3) }).to eq([5.245, 5.062, 5.0, 5.062, 5.245]) }
      it { expect(subject.values[-12, 5].map{ |v| v.hp.round(3) }).to eq([5.546, 5.247, 5.066, 5.006, 5.07]) }
      it { expect(subject.values[-12, 5].map{ |v| v.rsi.round(3) }).to eq([-1.0, -1.0, -1.0, -1.0, -1.0]) }
    end

    context "when price is at peak" do
      it { expect(subject.values[-32, 5].map{ |v| v.input.round(3) }).to eq([14.755, 14.938, 15.0, 14.938, 14.755]) }
      it { expect(subject.values[-32, 5].map{ |v| v.hp.round(3) }).to eq([14.454, 14.753, 14.934, 14.994, 14.93]) }
      it { expect(subject.values[-32, 5].map{ |v| v.rsi.round(3) }).to eq([1.0, 1.0, 1.0, 1.0, 1.0]) }
    end
  end
end
