# frozen_string_literal: true

RSpec.describe Quant::Indicators::Frama do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
  it { expect(subject.values.map{ |v| v.frama.round(3) }).to eq([3.0, 6.0, 12.0, 24.0]) }

  context "sine series" do
    let(:source) { :oc2 }
    let(:period) { 40 }
    let(:cycles) { 5 }
    let(:uniq_data_points) { cycles * period / cycles } # sine is cyclical, so we expect a few unique data points
    let(:series) { sine_series(period:, cycles:) }

    it { expect(subject.series.size).to eq(cycles * period) }

    it { expect(subject.values.last(5).map{ |v| v.frama.round(3) }).to eq([9.232, 9.206, 9.185, 9.173, 9.174]) }
    it { expect(subject.values.first(5).map{ |v| v.frama.round(3) }).to eq([10.0, 10.782, 11.545, 12.27, 12.939]) }
  end
end
