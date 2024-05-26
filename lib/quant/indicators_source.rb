# frozen_string_literal: true

module Quant
  # Dominant Cycles measure the primary cycle within a given range.  By default, the library
  # is wired to look for cycles between 10 and 48 bars.  These values can be adjusted by setting
  # the `min_period` and `max_period` configuration values in {Quant::Config}.
  #
  #    Quant.configure_indicators(min_period: 8, max_period: 32)
  #
  # The default dominant cycle kind is the `half_period` filter.  This can be adjusted by setting
  # the `dominant_cycle_kind` configuration value in {Quant::Config}.
  #
  #    Quant.configure_indicators(dominant_cycle_kind: :band_pass)
  #
  # The purpose of these indicators is to compute the dominant cycle and underpin the various
  # indicators that would otherwise be setting an arbitrary lookback period.  This makes the
  # indicators adaptive and auto-tuning to the market dynamics.  Or so the theory goes!
  class DominantCycles
    def initialize(indicator_source:)
      @indicator_source = indicator_source
    end

    # Auto-Correlation Reversals is a method of computing the dominant cycle
    # by correlating the data stream with itself delayed by a lag.
    def acr; indicator(Indicators::DominantCycles::Acr) end

    # The band-pass dominant cycle passes signals within a certain frequency
    # range, and attenuates signals outside that range.
    # The trend component of the signal is removed, leaving only the cyclical
    # component.  Then we count number of iterations between zero crossings
    # and this is the `period` of the dominant cycle.
    def band_pass; indicator(Indicators::DominantCycles::BandPass) end

    # Homodyne means the signal is multiplied by itself. More precisely,
    # we want to multiply the signal of the current bar with the complex
    # value of the signal one bar ago
    def homodyne; indicator(Indicators::DominantCycles::Homodyne) end

    # The Dual Differentiator algorithm computes the phase angle from the
    # analytic signal as the arctangent of the ratio of the imaginary
    # component to the real component. Further, the angular frequency
    # is defined as the rate change of phase. We can use these facts to
    # derive the cycle period.
    def differential; indicator(Indicators::DominantCycles::Differential) end

    # The phase accumulation method of computing the dominant cycle measures
    # the phase at each sample by taking the arctangent of the ratio of the
    # quadrature component to the in-phase component.  The phase is then
    # accumulated and the period is derived from the phase.
    def phase_accumulator; indicator(Indicators::DominantCycles::PhaseAccumulator) end

    # Static, arbitrarily set period.
    def half_period; indicator(Indicators::DominantCycles::HalfPeriod) end

    private

    def indicator(indicator_class)
      @indicator_source[indicator_class]
    end
  end

  # {Quant::IndicatorSource} holds a collection of {Quant::Indicators::Indicator} for a given input source.
  # This class ensures dominant cycle computations come before other indicators that depend on them.
  #
  # The {Quant::IndicatorSource} class is responsible for lazily loading indicators
  # so that not all indicators are always engaged and computing their values.
  # If the indicator is never accessed, it's never computed, saving valuable
  # processing CPU cycles.
  #
  # Indicators are generally built around the concept of a source input value and
  # that source is designated by the source parameter when instantiating the
  # {Quant::IndicatorSource} class.
  #
  # By design, the {Quant::Indicators::Indicator} class holds the {Quant::Ticks::Tick} instance
  # alongside the indicator's computed values for that tick.
  class IndicatorsSource
    attr_reader :series, :source, :dominant_cycles

    def initialize(series:, source:)
      @series = series
      @source = source
      @indicators = {}
      @ordered_indicators = []
      @dominant_cycles = DominantCycles.new(indicator_source: self)
    end

    def [](indicator_class)
      indicator(indicator_class)
    end

    def <<(tick)
      @ordered_indicators.each { |indicator| indicator << tick }
    end

    def ping; indicator(Indicators::Ping) end
    def adx; indicator(Indicators::Adx) end
    def atr; indicator(Indicators::Atr) end
    def mesa; indicator(Indicators::Mesa) end
    def mama; indicator(Indicators::MAMA) end

    # Attaches a given Indicator class and defines the method for
    # accessing it using the given name.  Indicators take care of
    # computing their values when first attached to a populated
    # series.
    #
    # The indicators shipped with the library are all wired into the framework, thus
    # this method should be used for custom indicators not shipped with the library.
    #
    # @param name [Symbol] The name of the method to define for accessing the indicator.
    # @param indicator_class [Class] The class of the indicator to attach.
    # @example
    #   series.indicators.oc2.attach(name: :foo, indicator_class: Indicators::Foo)
    def attach(name:, indicator_class:)
      define_singleton_method(name) { indicator(indicator_class) }
    end

    def dominant_cycle
      indicator(dominant_cycle_indicator_class)
    end

    private

    attr_reader :indicators, :ordered_indicators

    def dominant_cycle_indicator_class
      return @dominant_cycle_indicator_class if @dominant_cycle_indicator_class

      kind = Quant.config.indicators.dominant_cycle_kind.to_s
      base_class_name = kind.split("_").map(&:capitalize).join
      class_name = "Quant::Indicators::DominantCycles::#{base_class_name}"

      @dominant_cycle_indicator_class = Object.const_get(class_name)
    end

    # Instantiates the indicator class and stores it in the indicators hash.  Once
    # prepared, the indicator becomes active and all ticks pushed into the series
    # are sent to the indicator for processing.
    def indicator(indicator_class)
      indicators[indicator_class] ||= new_indicator(indicator_class)
    end

    def add_indicator(indicator_class, new_indicator)
      return if indicators[indicator_class]

      indicators[indicator_class] = new_indicator
      @ordered_indicators = (ordered_indicators << new_indicator).sort_by(&:priority)
      new_indicator
    end

    def add_dominant_cycle_indicator(dominant_cycle_class, indicator)
      return if indicator.is_a?(Indicators::DominantCycles::DominantCycle)
      return unless dominant_cycle_class
      return if indicators[dominant_cycle_class]

      dominant_cycle = dominant_cycle_class.new(series:, source:)
      add_indicator(dominant_cycle_class, dominant_cycle)
    end

    def new_indicator(indicator_class)
      indicator_class.new(series:, source:).tap do |indicator|
        add_dominant_cycle_indicator(indicator.dominant_cycle_indicator_class, indicator)
        add_indicator(indicator_class, indicator)
      end
    end

    def invalid_source_error(source:)
      raise InvalidIndicatorSource, "Invalid indicator source: #{source.inspect}"
    end
  end
end
