
# frozen_string_literal: true

RSpec.describe Quant::PivotsSource do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }
  let(:indicators_source) { Quant::IndicatorsSource.new(series:, source:) }

  subject { described_class.new(indicators_source:) }

  it { expect(subject.atr.band?(6)).to be_truthy }
  it { expect(subject.bollinger.band?(8)).to be_truthy }
  it { expect(subject.camarilla.band?(6)).to be_truthy }
  it { expect(subject.classic.band?(3)).to be_truthy }
  it { expect(subject.demark.band?(1)).to be_truthy }
  it { expect(subject.donchian.band?(3)).to be_truthy }
  it { expect(subject.fibbonacci.band?(7)).to be_truthy }
  it { expect(subject.guppy.band?(7)).to be_truthy }
  it { expect(subject.keltner.band?(6)).to be_truthy }
  it { expect(subject.murrey.band?(6)).to be_truthy }
  it { expect(subject.traditional.band?(3)).to be_truthy }
  it { expect(subject.woodie.band?(4)).to be_truthy }
end
