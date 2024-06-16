# frozen_string_literal: true

RSpec.describe Quant::Indicators::Roofing do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
  it { expect(subject.values.map{ |v| v.hp.round(3) }).to eq([0.0, 2.783, 7.937, 17.881]) }
  it { expect(subject.values.map{ |v| v.value.round(3) }).to eq([0.0, 0.056, 0.311, 1.006]) }
  it { expect(subject.values.map{ |v| v.peak.round(3) }).to eq([0.0, 0.056, 0.311, 1.006]) }
  it { expect(subject.values.map{ |v| v.agc.round(3) }).to eq([0, 1.0, 1.0, 1.0]) }

  context "sine series" do
    let(:source) { :oc2 }
    let(:period) { 40 }
    let(:cycles) { 1 }
    let(:series) { sine_series(period:, cycles:) }

    it { expect(subject.series.size).to eq(cycles * period) }

    # TODO: direction and turned need further analysis to confirm correctness
    xit { expect(subject.values.map(&:direction).group_by(&:itself).transform_values(&:count)).to eq({ 1 => 19, -1 => 21 }) }
    xit { expect(subject.values.map(&:turned).group_by(&:itself).transform_values(&:count)).to eq({ false => 34, true => 6 }) }

    context "tail end of the series" do
      it { expect(subject.values.last(5).map{ |v| v.value.round(3) }).to eq([-2.721, -2.353, -1.926, -1.449, -0.933]) }
      it { expect(subject.values.last(5).map{ |v| v.peak.round(3) }).to eq([3.324, 3.294, 3.264, 3.235, 3.206]) }
      it { expect(subject.values.last(5).map{ |v| v.agc.round(3) }).to eq([-0.818, -0.714, -0.59, -0.448, -0.291]) }
    end

    context "head of the series" do
      it { expect(subject.values.first(5).map{ |v| v.value.round(3) }).to eq([0.0, 0.015, 0.066, 0.164, 0.309]) }
      it { expect(subject.values.first(5).map{ |v| v.peak.round(3) }).to eq([0.0, 0.015, 0.066, 0.164, 0.309]) }
      it { expect(subject.values.first(5).map{ |v| v.agc.round(3) }).to eq([0, 1.0, 1.0, 1.0, 1.0]) }
    end
  end
end
