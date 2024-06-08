# frozen_string_literal: true

RSpec.describe Quant::Indicators::Pivots::Demark do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.values.map{ |v| v.input.round(3) }).to eq([14.0, 23.648, 47.348, 95.779]) }

  context "bands" do
    it { expect(subject.values.map{ |v| v.h1.round(3) }).to eq([3.0, 4.449, 8.724, 17.792]) }
    it { expect(subject.values.map{ |v| v.midpoint.round(3) }).to eq([3.5, 4.862, 9.271, 18.968]) }
    it { expect(subject.values.map{ |v| v.h0.round(3) }).to eq(subject.values.map{ |v| v.midpoint.round(3) }) }
    it { expect(subject.values.map{ |v| v.l1.round(3) }).to eq([5.0, 7.087, 13.633, 27.863]) }
  end
end
