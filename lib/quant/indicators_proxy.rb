# frozen_string_literal: true

module Quant
  # The {Quant::IndicatorsProxy} class is responsible for lazily loading indicators
  # so that not all indicators are always engaged and computing their values.
  # If the indicator is never accessed, it's never computed, saving valuable
  # processing CPU cycles.
  #
  # Indicators are generally built around the concept of a source input value and
  # that source is designated by the source parameter when instantiating the
  # {Quant::IndicatorsProxy} class.
  #
  # By design, the {Quant::Indicator} class holds the {Quant::Ticks::Tick} instance
  # alongside the indicator's computed values for that tick.
  class IndicatorsProxy
    attr_reader :series, :source, :indicators

    def initialize(series:, source:)
      @series = series
      @source = source
      @indicators = {}
    end

    # Instantiates the indicator class and stores it in the indicators hash.  Once
    # prepared, the indicator becomes active and all ticks pushed into the series
    # are sent to the indicator for processing.
    def indicator(indicator_class)
      indicators[indicator_class] ||= indicator_class.new(series:, source:)
    end

    # Adds the tick to all active indicators, triggering them to compute
    # new values against the latest tick.
    #
    # NOTE:  Dominant cycle indicators must be computed first as many
    # indicators are adaptive and require the dominant cycle period.
    # The IndicatorsProxy class is not responsible for enforcing
    # this order of events.
    def <<(tick)
      indicators.each_value { |indicator| indicator << tick }
    end

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

    def ma; indicator(Indicators::Ma) end
    def ping; indicator(Indicators::Ping) end
  end
end
