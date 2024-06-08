# frozen_string_literal: true

RSpec.describe Quant::Indicators::Pivots::Camarilla do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }

  context "bands" do
    it { expect(subject.values.map{ |v| v.range.round(3) }).to eq([2.0, 4.0, 8.0, 16.0]) }
    it { expect(subject.values.map{ |v| v.h6.round(3) }).to eq([8.0, 16.0, 32.0, 64.0]) }
    it { expect(subject.values.map{ |v| v.h5.round(3) }).to eq([7.84, 15.68, 31.36, 62.72]) }
    it { expect(subject.values.map{ |v| v.h4.round(3) }).to eq([7.0, 14.0, 28.0, 56.0]) }
    it { expect(subject.values.map{ |v| v.h3.round(3) }).to eq([6.5, 13.0, 26.0, 52.0]) }
    it { expect(subject.values.map{ |v| v.h2.round(3) }).to eq([6.334, 12.668, 25.336, 50.672]) }
    it { expect(subject.values.map{ |v| v.h1.round(3) }).to eq([6.166, 12.332, 24.664, 49.328]) }
    it { expect(subject.values.map{ |v| v.midpoint.round(3) }).to eq([3.333, 6.667, 13.333, 26.667]) }
    it { expect(subject.values.map{ |v| v.h0.round(3) }).to eq(subject.values.map{ |v| v.midpoint.round(3) }) }
    it { expect(subject.values.map{ |v| v.l1.round(3) }).to eq([1.834, 3.668, 7.336, 14.672]) }
    it { expect(subject.values.map{ |v| v.l2.round(3) }).to eq([1.666, 3.332, 6.664, 13.328]) }
    it { expect(subject.values.map{ |v| v.l3.round(3) }).to eq([1.5, 3.0, 6.0, 12.0]) }
    it { expect(subject.values.map{ |v| v.l4.round(3) }).to eq([1.0, 2.0, 4.0, 8.0]) }
    it { expect(subject.values.map{ |v| v.l5.round(3) }).to eq([0.16, 0.32, 0.64, 1.28]) }
    it { expect(subject.values.map{ |v| v.l6.round(3) }).to eq([0.0, 0.0, 0.0, 0.0]) }
  end
end
