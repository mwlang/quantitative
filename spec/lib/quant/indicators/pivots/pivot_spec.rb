# frozen_string_literal: true

RSpec.describe Quant::Indicators::Pivots::Pivot do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  context "extents" do
    it { expect(subject.values.map{ |v| v.highest.round(3) }).to eq([3.0, 6.0, 12.0, 24.0]) }
    it { expect(subject.values.map{ |v| v.avg_high.round(3) }).to eq([4.0, 4.529, 6.532, 11.585]) }
    it { expect(subject.values.map{ |v| v.lowest.round(3) }).to eq([3.0, 3.0, 3.0, 3.0]) }
    it { expect(subject.values.map{ |v| v.low_price.round(3) }).to eq([2.0, 4.0, 8.0, 16.0]) }
    it { expect(subject.values.map{ |v| v.high_price.round(3) }).to eq([4.0, 8.0, 16.0, 32.0]) }
    it { expect(subject.values.map{ |v| v.range.round(3) }).to eq([2.0, 4.0, 8.0, 16.0]) }
  end

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
  it { expect(subject.values.map(&:midpoint)).to eq([3.0, 6.0, 12.0, 24.0]) }

  it { expect(subject.values.map(&:highest)).to eq([3.0, 6.0, 12.0, 24.0]) }
  it { expect(subject.values.map(&:lowest)).to eq([3.0, 3.0, 3.0, 3.0]) }

  it { expect(subject.values.map(&:high_price)).to eq([4.0, 8.0, 16.0, 32.0]) }
  it { expect(subject.values.map(&:low_price)).to eq([2.0, 4.0, 8.0, 16.0]) }
  it { expect(subject.values.map(&:range)).to eq([2.0, 4.0, 8.0, 16.0]) }

  it { expect(subject.values.map{ |v| v.avg_high.round(3) }).to eq([4.0, 4.529, 6.532, 11.585]) }
  it { expect(subject.values.map{ |v| v.avg_low.round(3) }).to eq([2.0, 2.265, 3.266, 5.793]) }
  it { expect(subject.values.map{ |v| v.avg_range.round(3) }).to eq([0.265, 0.759, 2.17, 5.151]) }
end
