# frozen_string_literal: true

RSpec.describe Quant::Indicators::Pivots::Donchian do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }

  # TODO: Need a longer series run to test this properly
  context "bands" do
    it { expect(subject.values.map{ |v| v.h3.round(3) }).to eq([4.0, 8.0, 16.0, 32.0]) }
    it { expect(subject.values.map{ |v| v.h2.round(3) }).to eq([4.0, 8.0, 16.0, 32.0]) }
    it { expect(subject.values.map{ |v| v.h1.round(3) }).to eq([4.0, 8.0, 16.0, 32.0]) }
    it { expect(subject.values.map{ |v| v.midpoint.round(3) }).to eq([3.0, 6.0, 12.0, 24.0]) }
    it { expect(subject.values.map{ |v| v.h0.round(3) }).to eq(subject.values.map{ |v| v.midpoint.round(3) }) }
    it { expect(subject.values.map{ |v| v.l1.round(3) }).to eq([2.0, 2.0, 2.0, 2.0]) }
    it { expect(subject.values.map{ |v| v.l2.round(3) }).to eq([2.0, 2.0, 2.0, 2.0]) }
    it { expect(subject.values.map{ |v| v.l3.round(3) }).to eq([2.0, 2.0, 2.0, 2.0]) }
  end

  # TODO: Need a longer series run to test this properly
  xcontext "bands do not intersect each other" do
    %i[h3 h2 h1 midpoint l1 l2 l3].each_cons(2) do |above_band, below_band|
      it "band #{above_band.inspect} is above band #{below_band.inspect}" do
        compare_values = subject.values.drop(1) # first value is often zero, which isn't truthy for "positive?"
        expect(compare_values.map{ |v| v.send(above_band) - v.send(below_band) }).to all be_positive
      end
    end
  end
end
