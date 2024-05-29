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
    it { expect(subject.values.map{ |v| v.h5.round(3) }).to eq([5.227, 10.454, 20.909, 41.818]) }
    it { expect(subject.values.map{ |v| v.h4.round(3) }).to eq([3.3, 6.6, 13.2, 26.4]) }
    it { expect(subject.values.map{ |v| v.h3.round(3) }).to eq([1.65, 3.3, 6.6, 13.2]) }
    it { expect(subject.values.map{ |v| v.h2.round(3) }).to eq([1.1, 2.2, 4.4, 8.8]) }
    it { expect(subject.values.map{ |v| v.h1.round(3) }).to eq([0.55, 1.1, 2.2, 4.4]) }
    it { expect(subject.values.map{ |v| v.midpoint.round(3) }).to eq([4.0, 8.0, 16.0, 32.0]) }
    it { expect(subject.values.map{ |v| v.h0.round(3) }).to eq(subject.values.map{ |v| v.midpoint.round(3) }) }
    it { expect(subject.values.map{ |v| v.l1.round(3) }).to eq([0.183, 0.367, 0.733, 1.467]) }
    it { expect(subject.values.map{ |v| v.l2.round(3) }).to eq([0.367, 0.733, 1.467, 2.933]) }
    it { expect(subject.values.map{ |v| v.l3.round(3) }).to eq([0.55, 1.1, 2.2, 4.4]) }
    it { expect(subject.values.map{ |v| v.l4.round(3) }).to eq([1.1, 2.2, 4.4, 8.8]) }
    it { expect(subject.values.map{ |v| v.l5.round(3) }).to eq([1.742, 3.485, 6.97, 13.939]) }
    it { expect(subject.values.map{ |v| v.l6.round(3) }).to eq([0.0, 0.0, 0.0, 0.0]) }
  end
end
