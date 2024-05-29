# frozen_string_literal: true

RSpec.describe Quant::Indicators::Pivots::Classic do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }

  context "extents" do
    it { expect(subject.values.map{ |v| v.avg_low.round(3) }).to eq([2.0, 2.253, 3.013, 4.825]) }
    it { expect(subject.values.map{ |v| v.avg_high.round(3) }).to eq([4.0, 4.506, 6.026, 9.65]) }
    it { expect(subject.values.map{ |v| v.avg_range.round(3) }).to eq([0.506, 1.138, 1.897, 4.148]) }
  end

  context "bands" do
    it { expect(subject.values.map{ |v| v.h3.round(3) }).to eq([4.013, 5.655, 8.314, 15.533]) }
    it { expect(subject.values.map{ |v| v.h2.round(3) }).to eq([3.506, 4.518, 6.417, 11.385]) }
    it { expect(subject.values.map{ |v| v.h1.round(3) }).to eq([4.0, 4.506, 6.026, 9.65]) }
    it { expect(subject.values.map{ |v| v.midpoint.round(3) }).to eq([3.0, 3.38, 4.519, 7.238]) }
    it { expect(subject.values.map{ |v| v.h0.round(3) }).to eq(subject.values.map{ |v| v.midpoint.round(3) }) }
    it { expect(subject.values.map{ |v| v.l1.round(3) }).to eq([2.0, 2.253, 3.013, 4.825]) }
    it { expect(subject.values.map{ |v| v.l2.round(3) }).to eq([2.494, 2.242, 2.622, 3.09]) }
    it { expect(subject.values.map{ |v| v.l3.round(3) }).to eq([1.987, 1.104, 0.724, -1.058]) }
  end

  context "bands do not intersect each other" do
    %i[h3 h2 h1 midpoint l1 l2 l3].each_cons(2) do |above_band, below_band|
      it "band #{above_band.inspect} is above band #{below_band.inspect}" do
        compare_values = subject.values.drop(1) # first value is often zero, which isn't truthy for "positive?"
        expect(compare_values.map{ |v| v.send(above_band) - v.send(below_band) }).to all be_positive
      end
    end
  end
end
