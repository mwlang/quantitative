# frozen_string_literal: true

RSpec.describe Quant::Indicators::Pivots::Keltner do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }

  context "bands" do
    it { expect(subject.values.map{ |v| v.h6.round(3) }).to eq([3.0, 3.779, 6.231, 12.041]) }
    it { expect(subject.values.map{ |v| v.h1.round(3) }).to eq([3.0, 3.601, 5.354, 9.353]) }
    it { expect(subject.values.map{ |v| v.midpoint.round(3) }).to eq([3.0, 3.545, 5.083, 8.522]) }
    it { expect(subject.values.map{ |v| v.h0.round(3) }).to eq(subject.values.map{ |v| v.midpoint.round(3) }) }
    it { expect(subject.values.map{ |v| v.l1.round(3) }).to eq([3.0, 3.49, 4.812, 7.692]) }
    it { expect(subject.values.map{ |v| v.l6.round(3) }).to eq([3.0, 3.312, 3.934, 5.003]) }
  end

  context "bands do not intersect each other" do
    %i[h6 h5 h4 h3 h2 h1 midpoint l1 l2 l3 l4 l5 l6].each_cons(2) do |above_band, below_band|
      it "band #{above_band.inspect} is above band #{below_band.inspect}" do
        compare_values = subject.values.drop(1) # first value is often zero, which isn't truthy for "positive?"
        expect(compare_values.map{ |v| v.send(above_band) - v.send(below_band) }).to all be_positive
      end
    end
  end
end
