# frozen_string_literal: true

RSpec.describe Quant::Indicators::DominantCycles::BandPass do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { is_expected.to be_a(described_class) }
  it { expect(subject.series.size).to eq(4) }
  it { expect(subject.ticks.size).to eq(4) }
  it { expect(subject.p0).to eq subject.values[-1] }
  it { expect(subject.t0).to eq subject.ticks[-1] }

  context "sine series" do
    let(:series) do
      # 40 bar sine wave
      Quant::Series.new(symbol: "SINE", interval: "1d").tap do |series|
        3.times do
          (0..39).each do |degree|
            radians = degree * 2 * Math::PI / 40
            series << 5.0 * Math.sin(radians) + 10.0
          end
        end
      end
    end

    it { expect(subject.series.size).to eq(120) }
    it { expect(subject.p0.period).to eq 40 }
  end
end
