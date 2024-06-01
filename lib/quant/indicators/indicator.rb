# frozen_string_literal: true

module Quant
  module Indicators
    # The {Quant::Indicators::Indicator} class is the abstract ancestor for all Indicators.
    #
    class Indicator
      include Enumerable
      include Mixins::Functions
      include Mixins::Filters
      include Mixins::MovingAverages
      include Mixins::HilbertTransform
      include Mixins::SuperSmoother
      include Mixins::Stochastic
      include Mixins::FisherTransform
      # include Mixins::Direction

      # Provides a registry of dependent indicators for each indicator class.
      # NOTE: Internal use only.
      def self.dependent_indicator_classes
        @dependent_indicator_classes ||= Set.new
      end

      # Use the {depends_on} method to declare dependencies for an indicator.
      # @param indicator_classes [Array<Class>] The classes of the indicators to depend on.
      # @example
      #   class BarIndicator < Indicator
      #     depends_on FooIndicator
      #   end
      def self.depends_on(*indicator_classes)
        Array(indicator_classes).each{ |dependency| dependent_indicator_classes << dependency }
      end

      attr_reader :source, :series

      def initialize(series:, source:)
        @series = series
        @source = source
        @points = {}
        series.each { |tick| self << tick }
      end

      def dominant_cycle_indicator_class
        Quant.config.indicators.dominant_cycle_indicator_class
      end

      # The priority drives the order of computations when iterating over each tick
      # in a series.  Generally speaking, indicators that feed values to another indicator
      # must have a lower priority value than the indicator that consumes the values.
      #   * Most indicators will have a default priority of 1000.
      #   * Dominant Cycle indicators will have a priority of 100.
      #   * Some indicators will have a "high priority" of 500.
      # Priority values are arbitrary and purposefully gapping so that new indicators
      # introduced outside the core library can be slotted in between.
      #
      # NOTE: Priority is well-managed by the library and should not require overriding
      # for a custom indicator developed outside the library.  If you find yourself
      # needing to override this method, please open an issue on the library's GitHub page.
      PRIORITIES = [
        DOMINANT_CYCLES_PRIORITY = 100,
        DEPENDENCY_PRIORITY = 500,
        DEFAULT_PRIORITY = 1000
      ].freeze

      def priority
        DEFAULT_PRIORITY
      end

      def min_period
        Quant.config.indicators.min_period
      end

      def max_period
        Quant.config.indicators.max_period
      end

      def half_period
        Quant.config.indicators.half_period
      end

      def micro_period
        Quant.config.indicators.micro_period
      end

      def dominant_cycle_kind
        Quant.config.indicators.dominant_cycle_kind
      end

      def pivot_kind
        Quant.config.indicators.pivot_kind
      end

      def dominant_cycle
        series.indicators[source][dominant_cycle_indicator_class]
      end

      def dc_period
        dominant_cycle.points[t0].period
      end

      def ticks
        @points.keys
      end

      def [](index)
        values[index]
      end

      def values
        @points.values
      end

      def size
        @points.size
      end

      def period_points(max_period)
        extent = [values.size, max_period].min
        values[-extent, extent]
      end

      attr_reader :p0, :p1, :p2, :p3
      attr_reader :t0, :t1, :t2, :t3

      def <<(tick)
        @t0 = tick
        @p0 = points_class.new(indicator: self, tick:, source:)
        @points[tick] = @p0

        @p1 = values[-2] || @p0
        @p2 = values[-3] || @p1
        @p3 = values[-4] || @p2

        @t1 = ticks[-2] || @t0
        @t2 = ticks[-3] || @t1
        @t3 = ticks[-4] || @t2

        compute
      end

      def each(&block)
        @points.each_value(&block)
      end

      def inspect
        "#<#{self.class.name} symbol=#{series.symbol} source=#{source} ticks=#{ticks.size}>"
      end

      def compute
        raise NotImplementedError
      end

      def indicator_name
        self.class.name.split("::").last
      end

      def points_class
        Object.const_get "Quant::Indicators::#{indicator_name}Point"
      end

      # p(0) => values[-1]
      # p(1) => values[-2]
      # p(2) => values[-3]
      # p(3) => values[-4]
      def p(offset)
        raise ArgumentError, "offset must be a positive value" if offset < 0

        index = offset + 1
        values[[-index, -size].max]
      end

      # t(0) => ticks[-1]
      # t(1) => ticks[-2]
      # t(2) => ticks[-3]
      # t(3) => ticks[-4]
      def t(offset)
        raise ArgumentError, "offset must be a positive value" if offset < 0

        index = offset + 1
        ticks[[-index, -size].max]
      end

      # The input is the value derived from the source for the indicator
      # for the current tick.
      # For example, if the source is :oc2, then the input is the
      # value of the current tick's (open + close) / 2
      # @return [Numeric]
      def input
        t0.send(source)
      end

      # def warmed_up?
      #   true
      # end

      # attr_reader :dc_period

      # def points_for(series:)
      #   @points_for_cache[series] ||= self.class.new(series:, settings:, cloning: true).tap do |indicator|
      #     series.ticks.each { |tick| indicator.points.push(tick.indicators[self]) }
      #   end
      # end

      # # Ticks belong to the first series they're associated with always
      # # NOTE: No provisions for series merging their ticks to one series!
      # def parent_series
      #   series.ticks.empty? ? series : series.ticks.first.series
      # end

      # # Returns the last point of the current indicator rather than the entire series
      # # This is used for indicators that depend on dominant cycle or other indicators
      # # to compute their data points.
      # def current_point
      #   points.size - 1
      # end

      # def dominant_cycles
      #   parent_series.indicators.dominant_cycles
      # end

      # # Override this method to change source of dominant cycle computation for an indicator
      # def dominant_cycle_indicator
      #   @dominant_cycle_indicator ||= dominant_cycles.band_pass
      # end

      # def ensure_not_dominant_cycler_indicator
      #   return unless is_a? Quant::Indicators::DominantCycles::DominantCycle

      #   raise 'Dominant Cycle Indicators cannot use the thing they compute!'
      # end

      # # Returns the dominant cycle point for the current indicator's point
      # def current_dominant_cycle
      #   dominant_cycle_indicator[current_point]
      # end

      # # Returns the atr point for the current indicator's point
      # def atr_point
      #   parent_series.indicators.atr[current_point]
      # end

      # # def dc_period
      # #   dominant_cycle.period.round(0).to_i
      # # end

      # def <<(ohlc)
      #   points.append(ohlc)
      # end

      # def append(ohlc)
      #   points.append(ohlc)
      # end
    end
  end
end
