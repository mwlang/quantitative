# frozen_string_literal: true

module Quant
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
    attr_reader :series, :source, :dominant_cycles, :pivots

    def initialize(series:, source:)
      @series = series
      @source = source
      @indicators = {}
      @ordered_indicators = []
      @dominant_cycles = DominantCyclesSource.new(indicator_source: self)
      @pivots = PivotsSource.new(indicator_source: self)
    end

    def [](indicator_class)
      indicator(indicator_class)
    end

    def <<(tick)
      @ordered_indicators.each { |indicator| indicator << tick }
    end

    def adx; indicator(Indicators::Adx) end
    def atr; indicator(Indicators::Atr) end
    def cci; indicator(Indicators::Cci) end
    def decycler; indicator(Indicators::Decycler) end
    def frama; indicator(Indicators::Frama) end
    def mama; indicator(Indicators::Mama) end
    def mesa; indicator(Indicators::Mesa) end
    def ping; indicator(Indicators::Ping) end

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
      Quant.config.indicators.dominant_cycle_indicator_class
    end

    # Instantiates the indicator class and stores it in the indicators hash.  Once
    # prepared, the indicator becomes active and all ticks pushed into the series
    # are sent to the indicator for processing.
    def indicator(indicator_class)
      indicators[indicator_class] ||= new_indicator(indicator_class)
    end

    # Instantiates a new indicator and adds it to the collection of indicators.
    # This method is responsible for adding dependent indicators and the dominant cycle
    # indicator.
    def new_indicator(indicator_class)
      indicator_class.new(series:, source:).tap do |indicator|
        add_dominant_cycle_indicator(indicator.dominant_cycle_indicator_class, indicator)
        add_dependent_indicators(indicator_class.dependent_indicator_classes, indicator)
        add_indicator(indicator_class, indicator)
      end
    end

    # Adds a new indicator to the collection of indicators.  Once added, every
    # tick added to the series triggers the indicator's compute to fire.
    # The ordered indicators list is adjusted after adding the new indicator.
    def add_indicator(indicator_class, new_indicator)
      return if indicators[indicator_class]

      indicators[indicator_class] = new_indicator
      @ordered_indicators = (ordered_indicators << new_indicator).sort_by(&:priority)
      new_indicator
    end

    # Adds dependent indicators to the indicator collection.  This method is reentrant and
    # will also add depencies of the dependent indicators.
    # Dependent indicators automatically adjust priority based on the dependency.
    def add_dependent_indicators(indicator_classes, indicator)
      return if indicator_classes.empty?

      # Dependent indicators should come after dominant cycle indicators, but before the
      # indicators that depend on them.
      dependency_priority = (Quant::Indicators::Indicator::DEPENDENCY_PRIORITY + indicator.priority) / 2

      indicator_classes.each_with_index do |indicator_class, index|
        next if indicators[indicator_class]

        new_indicator = indicator_class.new(series:, source:)
        new_indicator.define_singleton_method(:priority) { dependency_priority + index }
        add_dependent_indicators(indicator_class.dependent_indicator_classes, new_indicator)
        add_indicator(indicator_class, new_indicator)
      end
    end

    # Adds the dominant cycle indicator to the collection of indicators.  Indicators added
    # by this method must be a subclass of {Quant::Indicators::DominantCycles::DominantCycle}.
    def add_dominant_cycle_indicator(dominant_cycle_class, indicator)
      return if indicator.is_a?(Indicators::DominantCycles::DominantCycle)
      return unless dominant_cycle_class
      return if indicators[dominant_cycle_class]

      dominant_cycle = dominant_cycle_class.new(series:, source:)
      add_indicator(dominant_cycle_class, dominant_cycle)
    end

    def invalid_source_error(source:)
      raise InvalidIndicatorSource, "Invalid indicator source: #{source.inspect}"
    end
  end
end
