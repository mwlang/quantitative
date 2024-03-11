# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::DominantCycleIndicators do
  let(:series) do
    # 40 bar sine wave
    Quant::Series.new(symbol: "SINE", interval: "1d").tap do |series|
      5.times do
        (0..39).each do |degree|
          radians = degree * 2 * Math::PI / 40
          series << 5.0 * Math.sin(radians) + 10.0
        end
      end
    end
  end
  let(:source) { :oc2 }

  subject { described_class.new(series:, source:) }

  it { expect(subject.acr.values[-1].period).to eq(40) }
  it { expect(subject.band_pass.values[-1].period).to eq(40) }
  it { expect(subject.homodyne.values[-1].period).to eq(40) }

  it { expect(subject.differential.values[-1].period).to eq(41) }
  it { expect(subject.phase_accumulator.values[-1].period).to eq(41) }
end
