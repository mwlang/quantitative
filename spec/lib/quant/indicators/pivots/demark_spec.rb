# frozen_string_literal: true

RSpec.describe Quant::Indicators::Pivots::Demark do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.values.map{ |v| v.input.round(3) }).to eq([14.0, 21.253, 39.011, 76.213]) }

  context "bands" do
    it { expect(subject.values.map{ |v| v.h1.round(3) }).to eq([3.0, 3.756, 5.621, 9.911]) }
    it { expect(subject.values.map{ |v| v.midpoint.round(3) }).to eq([3.5, 4.09, 5.726, 9.589]) }
    it { expect(subject.values.map{ |v| v.h0.round(3) }).to eq(subject.values.map{ |v| v.midpoint.round(3) }) }
    it { expect(subject.values.map{ |v| v.l1.round(3) }).to eq([5.0, 5.968, 8.536, 14.544]) }
  end
end
