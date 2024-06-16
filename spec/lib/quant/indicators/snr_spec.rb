# frozen_string_literal: true

RSpec.describe Quant::Indicators::Snr do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
  it { expect(subject.values.map{ |v| v.signal.round(3) }).to eq([0.0, -39.404, -29.507, -16.314]) }
  it { expect(subject.values.map{ |v| v.noise.round(3) }).to eq([0.0, 3.0, 3.6, 5.04]) }
  it { expect(subject.values.map{ |v| v.ratio.round(3) }).to eq([1.0, -9.101, -14.202, -14.73]) }

  context "sine series" do
    let(:source) { :oc2 }
    let(:period) { 40 }
    let(:cycles) { 5 }
    let(:series) { sine_series(period:, cycles:) }

    context "expect signal to follow sine wave cycles" do
      it { expect(subject.values.last(5).map{ |v| v.signal.round(3) }).to eq([19.914, 19.55, 19.082, 18.569, 18.064]) }
      it { expect(subject.values.last(20).first(5).map{ |v| v.signal.round(3) }).to eq([17.605, 17.216, 16.913, 16.703, 16.593]) }
      it { expect(subject.values.last(10).first(5).map{ |v| v.signal.round(3) }).to eq([18.331, 19.182, 19.769, 20.073, 20.108]) }
    end

    context "expect noise to follow sine wave cycles" do
      it { expect(subject.values.last(5).map{ |v| v.noise.round(3) }).to eq([0.787, 0.819, 0.863, 0.916, 0.973]) }
      it { expect(subject.values.last(20).first(5).map{ |v| v.noise.round(3) }).to eq([1.031, 1.084, 1.13, 1.166, 1.189]) }
      it { expect(subject.values.last(10).first(5).map{ |v| v.noise.round(3) }).to eq([0.972, 0.874, 0.811, 0.779, 0.772]) }
    end

    context "expect ratio to follow sine wave cycles" do
      it { expect(subject.values.last(5).map{ |v| v.ratio.round(3) }).to eq([19.325, 19.381, 19.306, 19.122, 18.858]) }
      it { expect(subject.values.last(20).first(5).map{ |v| v.ratio.round(3) }).to eq([18.544, 18.212, 17.888, 17.591, 17.342]) }
      it { expect(subject.values.last(10).first(5).map{ |v| v.ratio.round(3) }).to eq([17.493, 17.916, 18.379, 18.802, 19.129]) }
    end

    it "The state is takes half the first sine cycle to reach 1" do
      warmup_period = period / 2
      half_warmup_period = warmup_period / 2
      counts = subject.values.map(&:state).group_by(&:itself).transform_values(&:count)
      expect(counts[0]).to be < warmup_period
      expect(counts[0]).to be > half_warmup_period
      expect(counts[1]).to be > period * 4
    end
  end
end
