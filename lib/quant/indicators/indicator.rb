# frozen_string_literal: true

module Quant
  class Indicators
    class Indicator
      include Enumerable
      include Mixins::Functions
      include Mixins::Filters
      include Mixins::MovingAverages
      # include Mixins::HilbertTransform
      # include Mixins::SuperSmoother
      # include Mixins::Stochastic
      # include Mixins::FisherTransform
      # include Mixins::HighPassFilter
      # include Mixins::Direction
      # include Mixins::Filters

      attr_reader :source, :series

      def initialize(series:, source:)
        @series = series
        @source = source
        @points = {}
        series.each { |tick| self << tick }
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

      attr_reader :p0, :p1, :p2, :p3
      attr_reader :t0, :t1, :t2, :t3

      def <<(tick)
        @t0 = tick
        @p0 = points_class.new(tick:, source:)
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
