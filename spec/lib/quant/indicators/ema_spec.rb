# frozen_string_literal: true

RSpec.describe Quant::Indicators::Ema do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }

  context "EMA" do
    it { expect(subject.values.map{ |v| v.ema_dc_period.round(3) }).to eq([3.0, 3.2, 3.787, 5.134]) }
    it { expect(subject.values.map{ |v| v.ema_half_dc_period.round(3) }).to eq([3.0, 3.4, 4.547, 7.14]) }
    it { expect(subject.values.map{ |v| v.ema_micro_period.round(3) }).to eq([3.0, 4.5, 8.25, 16.125]) }
    it { expect(subject.values.map{ |v| v.ema_min_period.round(3) }).to eq([3.0, 3.545, 5.083, 8.522]) }
    it { expect(subject.values.map{ |v| v.ema_max_period.round(3) }).to eq([3.0, 3.122, 3.485, 4.322]) }
  end

  context "SS" do
    it { expect(subject.values.map{ |v| v.ss_dc_period.round(3) }).to eq([3.0, 3.06, 3.242, 3.707]) }
    it { expect(subject.values.map{ |v| v.ss_half_dc_period.round(3) }).to eq([3.0, 3.22, 3.88, 5.504]) }
    it { expect(subject.values.map{ |v| v.ss_micro_period.round(3) }).to eq([3.0, 4.516, 9.065, 18.226]) }
    it { expect(subject.values.map{ |v| v.ss_min_period.round(3) }).to eq([3.0, 3.38, 4.519, 7.238]) }
    it { expect(subject.values.map{ |v| v.ss_max_period.round(3) }).to eq([3.0, 3.023, 3.094, 3.277]) }
  end

  context "oscillators" do
    it { expect(subject.values.map{ |v| v.osc_dc_period.round(3) }).to eq([0.0, -0.14, -0.545, -1.428]) }
    it { expect(subject.values.map{ |v| v.osc_half_dc_period.round(3) }).to eq([0.0, -0.18, -0.667, -1.636]) }
    it { expect(subject.values.map{ |v| v.osc_micro_period.round(3) }).to eq([0.0, 0.016, 0.815, 2.101]) }
    it { expect(subject.values.map{ |v| v.osc_min_period.round(3) }).to eq([0.0, -0.166, -0.563, -1.284]) }
    it { expect(subject.values.map{ |v| v.osc_max_period.round(3) }).to eq([0.0, -0.099, -0.391, -1.045]) }
  end
end
