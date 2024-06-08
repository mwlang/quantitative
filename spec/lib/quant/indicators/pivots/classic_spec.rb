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

  context "bands" do
    it { expect(subject.values.map{ |v| v.h3.round(3) }).to eq([3.529, 4.915, 9.239, 18.991]) }
    it { expect(subject.values.map{ |v| v.h2.round(3) }).to eq([3.265, 4.156, 7.069, 13.84]) }
    it { expect(subject.values.map{ |v| v.h1.round(3) }).to eq([4.0, 4.529, 6.532, 11.585]) }
    it { expect(subject.values.map{ |v| v.midpoint.round(3) }).to eq([3.0, 3.397, 4.899, 8.689]) }
    it { expect(subject.values.map{ |v| v.h0.round(3) }).to eq(subject.values.map{ |v| v.midpoint.round(3) }) }
    it { expect(subject.values.map{ |v| v.l1.round(3) }).to eq([2.0, 2.265, 3.266, 5.793]) }
    it { expect(subject.values.map{ |v| v.l2.round(3) }).to eq([2.735, 2.638, 2.729, 3.538]) }
    it { expect(subject.values.map{ |v| v.l3.round(3) }).to eq([2.471, 1.879, 0.559, -1.613]) }
  end
end
