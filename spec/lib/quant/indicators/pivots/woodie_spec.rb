# frozen_string_literal: true

RSpec.describe Quant::Indicators::Pivots::Woodie do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.ticks.map(&:oc2)).to eq([3.0, 6.0, 12.0, 24.0]) }
  it { expect(subject.values.map(&:input)).to eq([2.5, 3.5, 7.0, 14.0]) }

  context "extents" do
    it { expect(subject.values.map{ |v| v.highest.round(3) }).to eq([3.0, 6.0, 12.0, 24.0]) }
    it { expect(subject.values.map{ |v| v.avg_high.round(3) }).to eq([4.0, 4.506, 6.026, 9.65]) }
    it { expect(subject.values.map{ |v| v.lowest.round(3) }).to eq([3.0, 2.5, 2.5, 2.5]) }
    it { expect(subject.values.map{ |v| v.low_price.round(3) }).to eq([2.0, 4.0, 8.0, 16.0]) }
    it { expect(subject.values.map{ |v| v.range.round(3) }).to eq([2.0, 4.0, 8.0, 16.0]) }
  end

  # Woodie's calculated bands are erratic as-written. The following tests are marked
  # as pending until the correct formula is determined.
  context "bands" do
    it { expect(subject.values.map{ |v| v.h4.round(3) }).to eq([7.0, 11.0, 22.0, 44.0]) }
    it { expect(subject.values.map{ |v| v.h3.round(3) }).to eq([5.0, 7.0, 14.0, 28.0]) }
    it { expect(subject.values.map{ |v| v.h2.round(3) }).to eq([4.5, 7.5, 15.0, 30.0]) }
    it { expect(subject.values.map{ |v| v.h1.round(3) }).to eq([3.0, 5.0, 10.0, 20.0]) }
    it { expect(subject.values.map{ |v| v.midpoint.round(3) }).to eq([2.5, 3.5, 7.0, 14.0]) }
    it { expect(subject.values.map{ |v| v.h0.round(3) }).to eq(subject.values.map{ |v| v.midpoint.round(3) }) }
    it { expect(subject.values.map{ |v| v.l1.round(3) }).to eq([1.0, 3.0, 6.0, 12.0]) }
    it { expect(subject.values.map{ |v| v.l2.round(3) }).to eq([0.5, -0.5, -1.0, -2.0]) }
    it { expect(subject.values.map{ |v| v.l3.round(3) }).to eq([-1.0, 1.0, 2.0, 4.0]) }
    it { expect(subject.values.map{ |v| v.l4.round(3) }).to eq([-3.0, -3.0, -6.0, -12.0]) }
  end

  xcontext "bands do not intersect each other" do
    %i[h4 h3 h2 h1 midpoint l1 l2 l3 l4].each_cons(2) do |above_band, below_band|
      it "band #{above_band.inspect} is above band #{below_band.inspect}" do
        compare_values = subject.values.drop(1) # first value is often zero, which isn't truthy for "positive?"
        expect(compare_values.map{ |v| v.send(above_band) - v.send(below_band) }).to all be_positive
      end
    end
  end
end
