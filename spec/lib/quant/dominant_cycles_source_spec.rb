# frozen_string_literal: true

RSpec.describe Quant::DominantCyclesSource do
  let(:source) { :oc2 }
  let(:indicators_source) { Quant::IndicatorsSource.new(series:, source:) }
  let(:series) { sine_series(period: 40, cycles: 5) }

  subject { described_class.new(indicators_source:) }

  it { expect(subject.acr.values[-1].period).to eq(40) }
  it { expect(subject.band_pass.values[-1].period).to eq(40) }
  it { expect(subject.homodyne.values[-1].period).to eq(40) }

  it { expect(subject.differential.values[-1].period).to eq(41) }
  it { expect(subject.phase_accumulator.values[-1].period).to eq(41) }
  it { expect(subject.half_period.values[-1].period).to eq(29) }
end
