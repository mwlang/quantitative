# frozen_string_literal: true

RSpec.describe Quant::Indicators::Pivots::Bollinger do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
  it { expect(subject.values.map{ |v| v.std_dev.round(3) }).to eq([0.0, 1.985, 4.985, 10.365]) }

  context "bands" do
    it { expect(subject.values.map{ |v| v.h6.round(3) }).to eq([3.0, 8.162, 16.168, 30.624]) }
    it { expect(subject.values.map{ |v| v.h1.round(3) }).to eq([3.0, 5.185, 8.691, 15.077]) }
    it { expect(subject.values.map{ |v| v.midpoint.round(3) }).to eq([3.0, 3.2, 3.707, 4.712]) }
    it { expect(subject.values.map{ |v| v.h0.round(3) }).to eq(subject.values.map{ |v| v.midpoint.round(3) }) }
    it { expect(subject.values.map{ |v| v.l1.round(3) }).to eq([3.0, 1.215, -1.278, -5.652]) }
    it { expect(subject.values.map{ |v| v.l6.round(3) }).to eq([3.0, -1.762, -8.755, -21.199]) }
  end

  context "bands do not intersect each other" do
    %i[h8 h7 h6 h5 h4 h3 h2 h1 midpoint l1 l2 l3 l4 l5 l6 l7 l8].each_cons(2) do |above_band, below_band|
      it "band #{above_band.inspect} is above band #{below_band.inspect}" do
        compare_values = subject.values.drop(1) # first value is often zero, which isn't truthy for "positive?"
        expect(compare_values.map{ |v| v.send(above_band) - v.send(below_band) }).to all be_positive
      end
    end
  end
end
