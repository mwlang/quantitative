# frozen_string_literal: true

RSpec.describe Quant::IndicatorsSource do
  let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
  let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
  let(:source) { :oc2 }
  let(:indicator_class) { Quant::Indicators::Ping }
  let(:indicator) { indicator_class.new(series:, source:) }

  subject { described_class.new(series:, source:) }

  it { expect(subject.dominant_cycle).to be_a(Quant::Indicators::DominantCycles::HalfPeriod) }

  it "after adding an indicator" do
    indicator = subject[indicator_class]

    expect(indicator).to be_a(indicator_class)
    expect(indicator.series).to eq(series)

    expect(subject[indicator_class]).to eq(indicator)
  end

  describe "Pivot Indicators" do
    it { expect(subject.pivots.atr.band?(6)).to be_truthy }
    it { expect(subject.pivots.bollinger.band?(8)).to be_truthy }
    it { expect(subject.pivots.camarilla.band?(6)).to be_truthy }
    it { expect(subject.pivots.classic.band?(3)).to be_truthy }
    it { expect(subject.pivots.demark.band?(1)).to be_truthy }
    it { expect(subject.pivots.donchian.band?(3)).to be_truthy }
    it { expect(subject.pivots.fibbonacci.band?(7)).to be_truthy }
    it { expect(subject.pivots.guppy.band?(7)).to be_truthy }
    it { expect(subject.pivots.keltner.band?(6)).to be_truthy }
    it { expect(subject.pivots.murrey.band?(6)).to be_truthy }
    it { expect(subject.pivots.traditional.band?(3)).to be_truthy }
    it { expect(subject.pivots.woodie.band?(4)).to be_truthy }
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

  context "adding an indicator with a dependency" do
    let!(:foo_indicator_class) do
      Quant::Indicators::FooPoint ||= Class.new(Quant::Indicators::PingPoint)
      Class.new(Quant::Indicators::Ping).tap do |klass|
        klass.define_method(:points_class) { Quant::Indicators::PingPoint }
      end
    end
    let!(:bar_indicator_class) do
      Class.new(Quant::Indicators::Ping).tap do |klass|
        klass.define_method(:points_class) { Quant::Indicators::PingPoint }
      end
    end
    let!(:baz_indicator_class) do
      Class.new(Quant::Indicators::Ping).tap do |klass|
        klass.define_method(:points_class) { Quant::Indicators::PingPoint }
      end
    end

    context "when a single dependency class" do
      before do
        bar_indicator_class.depends_on foo_indicator_class
      end

      it "includes the dependent class" do
        subject[bar_indicator_class]

        dc_indicator = subject.instance_variable_get(:@ordered_indicators)[0]
        foo = subject.instance_variable_get(:@ordered_indicators)[1]
        bar = subject.instance_variable_get(:@ordered_indicators)[2]

        expect(dc_indicator).to be_a Quant::Indicators::DominantCycles::DominantCycle
        expect(dc_indicator.priority).to be < foo.priority
        expect(subject.instance_variable_get(:@ordered_indicators)).to eq([dc_indicator, foo, bar])
        expect(subject.instance_variable_get(:@ordered_indicators).map(&:priority)).to eq([100, 750, 1000])
      end
    end

    context "when dependency of a dependency" do
      before do
        bar_indicator_class.depends_on foo_indicator_class
        baz_indicator_class.depends_on bar_indicator_class
      end

      it "includes the dependent of dependent class" do
        subject[baz_indicator_class]

        dc_indicator = subject.instance_variable_get(:@ordered_indicators)[0]
        foo = subject.instance_variable_get(:@ordered_indicators)[1]
        bar = subject.instance_variable_get(:@ordered_indicators)[2]
        baz = subject.instance_variable_get(:@ordered_indicators)[3]

        expect(dc_indicator).to be_a Quant::Indicators::DominantCycles::DominantCycle
        expect(dc_indicator.priority).to be < foo.priority
        expect(subject.instance_variable_get(:@ordered_indicators)).to eq([dc_indicator, foo, bar, baz])
        expect(subject.instance_variable_get(:@ordered_indicators).map(&:priority)).to eq([100, 625, 750, 1000])
      end
    end

    context "when two dependencies separate lines" do
      before do
        baz_indicator_class.depends_on foo_indicator_class
        baz_indicator_class.depends_on bar_indicator_class
      end

      it "includes the dependent of dependent class" do
        subject[baz_indicator_class]
        dc_indicator, foo, bar, baz = subject.instance_variable_get(:@ordered_indicators)

        expect(dc_indicator).to be_a Quant::Indicators::DominantCycles::DominantCycle
        expect(subject.instance_variable_get(:@ordered_indicators)).to eq([dc_indicator, foo, bar, baz])
        expect(subject.instance_variable_get(:@ordered_indicators).map(&:priority)).to eq([100, 750, 751, 1000])
      end
    end

    context "when two dependencies same line" do
      before do
        baz_indicator_class.depends_on foo_indicator_class, bar_indicator_class
      end

      it "includes the dependent of dependent class" do
        subject[baz_indicator_class]
        dc_indicator, foo, bar, baz = subject.instance_variable_get(:@ordered_indicators)

        expect(dc_indicator).to be_a Quant::Indicators::DominantCycles::DominantCycle
        expect(foo).to be_a foo_indicator_class
        expect(bar).to be_a bar_indicator_class
        expect(subject.instance_variable_get(:@ordered_indicators)).to eq([dc_indicator, foo, bar, baz])
        expect(subject.instance_variable_get(:@ordered_indicators).map(&:priority)).to eq([100, 750, 751, 1000])
      end
    end

    context "order matters when two dependencies" do
      before do
        baz_indicator_class.depends_on bar_indicator_class, foo_indicator_class
      end

      it "includes the dependent of dependent class" do
        subject[baz_indicator_class]
        dc_indicator, bar, foo, baz = subject.instance_variable_get(:@ordered_indicators)

        expect(dc_indicator).to be_a Quant::Indicators::DominantCycles::DominantCycle
        expect(foo).to be_a foo_indicator_class
        expect(bar).to be_a bar_indicator_class
        expect(subject.instance_variable_get(:@ordered_indicators)).to eq([dc_indicator, bar, foo, baz])
        expect(subject.instance_variable_get(:@ordered_indicators).map(&:priority)).to eq([100, 750, 751, 1000])
      end
    end
  end
end
