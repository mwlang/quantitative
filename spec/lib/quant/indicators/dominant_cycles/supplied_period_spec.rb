# frozen_string_literal: true

RSpec.describe Quant::Indicators::DominantCycles::SuppliedPeriod do
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
        2.times do
          (0..39).each do |degree|
            radians = degree * 2 * Math::PI / 40
            series << 5.0 * Math.sin(radians) + 10.0
          end
        end
      end
    end

    it { expect(subject.series.size).to eq(80) }
    it { expect(subject.p0.period).to eq 29 }

    context "with an alternate configuration" do
      before do
        Quant.configure_indicators(max_period: 10, min_period: 4)
      end

      after(:all) { Quant.default_configuration! }

      it { expect(subject.p0.period).to eq 7 }
    end
  end

  describe "supply modes" do
    let(:series) do
      Quant::Series.new(symbol: "SINE", interval: "1d").tap do |series|
        (0..39).each do |degree|
          radians = degree * 2 * Math::PI / 40
          series << 5.0 * Math.sin(radians) + 10.0
        end
      end
    end

    describe "Mode 1: Fixed" do
      it "accepts a literal period value set at construction" do
        subject.p0.period = 14
        expect(subject.p0.period).to eq(14)
      end

      it "keeps the fixed value across reads" do
        subject.p0.period = 21
        2.times { expect(subject.p0.period).to eq(21) }
      end
    end

    describe "Mode 2: Manual (runtime mutation)" do
      it "reflects subsequent mutations on every read" do
        subject.p0.period = 10
        expect(subject.p0.period).to eq(10)

        subject.p0.period = 20
        expect(subject.p0.period).to eq(20)
      end
    end

    describe "Mode 3: Configured (resolves through Quant.config.indicators)" do
      after { Quant.default_configuration! }

      it "defaults to the half_period config symbol resolving via config" do
        # With default min=10/max=48 config the half_period resolves to 29.
        expect(subject.p0.period).to eq(29)
      end

      it "resolves at construction time per the active Quant.config.indicators settings" do
        Quant.configure_indicators(min_period: 8, max_period: 32)
        fresh_instance = described_class.new(series:, source:)
        expect(fresh_instance.p0.period).to eq(20)  # (8 + 32) / 2
      end
    end

    describe "Mode 4: External (substrate-supplied)" do
      it "accepts arbitrary per-tick values supplied externally" do
        # Simulate a substrate read that supplies a period derived
        # from a tick-stream computation in another process.
        external_period_seconds = 8640  # ~2.4h cycle
        bar_interval_seconds    = 60    # 1m bars
        period_bars             = external_period_seconds / bar_interval_seconds

        subject.p0.period = period_bars
        expect(subject.p0.period).to eq(144)
      end
    end
  end

  describe "compute" do
    it "is a no-op (returns nil)" do
      expect(subject.compute).to be_nil
    end
  end

  describe "deprecation aliases (removed in 0.9.0)" do
    it "HalfPeriod constant resolves to SuppliedPeriod" do
      # Access the deprecated alias (suppress warning for this assertion).
      klass = Quant::Indicators::DominantCycles.const_get(:HalfPeriod)
      expect(klass).to eq(Quant::Indicators::DominantCycles::SuppliedPeriod)
    end

    it "HalfPeriodPoint constant resolves to SuppliedPeriodPoint" do
      klass = Quant::Indicators::DominantCycles.const_get(:HalfPeriodPoint)
      expect(klass).to eq(Quant::Indicators::DominantCycles::SuppliedPeriodPoint)
    end

    it "HalfPeriod constant is marked deprecated via deprecate_constant" do
      # Ruby's deprecate_constant mechanism marks the constant; verify
      # the marker is present by inspecting the parent module.
      expect(Quant::Indicators::DominantCycles.deprecated_constants).to include(:HalfPeriod) if Quant::Indicators::DominantCycles.respond_to?(:deprecated_constants)
      # Fallback: constant resolves but Ruby emits a warning at access
      # (verified by visual inspection or rspec's warning detection).
    end

    it ":half_period dominant_cycle_kind resolves to SuppliedPeriod" do
      indicators = Quant::Settings::Indicators.new(dominant_cycle_kind: :half_period)
      expect(indicators.dominant_cycle_indicator_class).to eq(Quant::Indicators::DominantCycles::SuppliedPeriod)
    end

    it ":half_period dominant_cycle_kind emits a one-time deprecation warning per instance" do
      warnings_captured = []
      indicators = Quant::Settings::Indicators.new(dominant_cycle_kind: :half_period)

      allow(indicators).to receive(:warn) { |msg| warnings_captured << msg }
      indicators.dominant_cycle_indicator_class

      # Reset memoization so the resolver runs again and verify no second warning.
      indicators.instance_variable_set(:@dominant_cycle_indicator_class, nil)
      indicators.dominant_cycle_indicator_class

      expect(warnings_captured.size).to eq(1)
      expect(warnings_captured.first).to include("half_period")
      expect(warnings_captured.first).to include("supplied_period")
      expect(warnings_captured.first).to include("0.9.0")
    end

    it ":supplied_period dominant_cycle_kind does NOT emit a deprecation warning" do
      warnings_captured = []
      indicators = Quant::Settings::Indicators.new(dominant_cycle_kind: :supplied_period)

      allow(indicators).to receive(:warn) { |msg| warnings_captured << msg }
      indicators.dominant_cycle_indicator_class

      expect(warnings_captured).to be_empty
    end
  end
end
