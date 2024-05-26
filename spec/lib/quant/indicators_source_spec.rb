# frozen_string_literal: true

RSpec.describe Quant::IndicatorsSource do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }
  let(:indicator_class) { Quant::Indicators::Ping }
  let(:indicator) { indicator_class.new(series:, source:) }

  subject { described_class.new(series:, source:) }

  it "after adding an indicator" do
    indicator = subject[indicator_class]

    expect(indicator).to be_a(indicator_class)
    expect(indicator.series).to eq(series)

    expect(subject[indicator_class]).to eq(indicator)
  end

  describe "Dominant Cycle Indicators" do
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

    it { expect(subject.dominant_cycle.values[-1].period).to eq(29) }

    it { expect(subject.dominant_cycles.acr.values[-1].period).to eq(40) }
    it { expect(subject.dominant_cycles.band_pass.values[-1].period).to eq(40) }
    it { expect(subject.dominant_cycles.homodyne.values[-1].period).to eq(40) }

    it { expect(subject.dominant_cycles.differential.values[-1].period).to eq(41) }
    it { expect(subject.dominant_cycles.phase_accumulator.values[-1].period).to eq(41) }
    it { expect(subject.dominant_cycles.half_period.values[-1].period).to eq(29) }
  end

  context "priority ordering" do
    let(:dominant_cycle) { Quant::Indicators::DominantCycles::HalfPeriod }
    let(:ping) { Quant::Indicators::Ping }

    it "dominant cycle indicator has higher priority" do
      a = subject[dominant_cycle]
      b = subject[ping]

      expect(subject[dominant_cycle].priority).to be < subject[ping].priority
      expect(subject.instance_variable_get(:@ordered_indicators)).to eq([a, b])
    end

    it "dominant cycle indicator has higher priority when reversed" do
      b = subject[ping]
      a = subject[dominant_cycle]

      expect(subject[dominant_cycle].priority).to be < subject[ping].priority
      expect(subject.instance_variable_get(:@ordered_indicators)).to eq([a, b])
    end

    it "adds new indicator and dominant cycle indicator" do
      subject[ping]
      dc_indicator = subject.instance_variable_get(:@ordered_indicators).first
      new_indicator = subject.instance_variable_get(:@ordered_indicators).last

      expect(new_indicator).to be_a ping
      expect(dc_indicator).to be_a Quant::Indicators::DominantCycles::DominantCycle
    end
  end
end
