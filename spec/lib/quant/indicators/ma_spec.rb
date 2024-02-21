# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Indicators::Ma do
  let(:apple_fixture_filename) { fixture_filename("AAPL-19990104_19990107.txt", :series) }
  let(:series) { Quant::Series.from_file(filename: apple_fixture_filename, symbol: "AAPL", interval: "1d") }

  subject { described_class.new(series: series) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  # it { expect(subject.points).to be_a(Quant::Indicators::Points) }
  # it { expect(subject.points.size).to eq(4) }
  # it { expect(subject.points.iteration).to eq(4) }
  # it { expect(subject.points.p0).to eq subject.points[-1] }
  # it { expect(subject.points.p1).to eq subject.points[-2] }
  # it { expect(subject.points.p2).to eq subject.points[-3] }
  # it { expect(subject.points.p3).to eq subject.points[-4] }
end
