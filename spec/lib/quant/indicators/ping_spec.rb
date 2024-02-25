# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Indicators::Ping do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename: filename, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series: series, source: source) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.ticks.first).to be_a(Quant::Ticks::Tick) }
  it { expect(subject.values.first).to be_a(Quant::Indicators::PingPoint) }
  it { expect(subject.ticks.size).to eq(4) }
  it { expect(subject.p0.pong).to eq 24 }
  it { expect(subject.p1.pong).to eq 12 }
  it { expect(subject.p2.pong).to eq 6 }
  it { expect(subject.p3.pong).to eq 3 }
  it { expect(subject.p1).to eq subject.values[-2] }
  it { expect(subject.p2).to eq subject.values[-3] }
  it { expect(subject.p3).to eq subject.values[-4] }
  it { expect(subject.values.map(&:compute_count)).to be_all 1 }
end
