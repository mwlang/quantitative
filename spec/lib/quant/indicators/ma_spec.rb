# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Indicators::Ma do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks).to be_a(Array) }
  it { expect(subject.ticks.first).to be_a(Quant::Ticks::Tick) }
  it { expect(subject.values.first).to be_a(Quant::Indicators::MaPoint) }
  it { expect(subject.ticks.size).to eq(4) }
  it { expect(subject.p0.ema).to eq 4.322153184472455 }
  it { expect(subject.p1.ema).to eq 3.4847980008329857 }
  it { expect(subject.p2.ema).to eq 3.1224489795918364 }
  it { expect(subject.p3.ema).to eq 3.0 }
end
