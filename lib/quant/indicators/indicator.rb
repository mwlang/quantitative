module Quant
  class Indicators
    class Indicator
      # include Enumerable

      # # include Mixins::TrendMethods
      # include Mixins::Trig
      # include Mixins::WeightedAverage
      # include Mixins::HilbertTransform
      # include Mixins::SuperSmoother
      # include Mixins::Stochastic
      # include Mixins::FisherTransform
      # include Mixins::HighPassFilter
      # include Mixins::Direction
      # include Mixins::Filters

      # def inspect
      #   "#<#{self.class.name} #{symbol} #{interval} #{points.size} points>"
      # end

      # def compute
      #   raise NotImplementedError
      # end

      # def [](index)
      #   points[index]
      # end

      # def after_append
      #   # NoOp
      # end

      # def points_class
      #   "Quant::Indicators::#{indicator_name}Point".constantize
      # end

      # def indicator_name
      #   self.class.name.demodulize
      # end

      # def warmed_up?
      #   true
      # end

      # def initial_max_size
      #   value = [series.size, series.max_size].max
      #   value.zero? ? settings.initial_max_size : value
      # end

      attr_reader :series #, :settings, :max_size, :points, :dc_period
      # delegate :p0, :p1, :p2, :p3, :prev, :iteration, to: :points
      # delegate :each, :size, :[], :last, :first, to: :points
      # delegate :oc2, :high_price, :low_price, :open_price, :close_price, :volume, to: :p0

      def initialize(series:) # settings: Settings::Indicators.defaults, cloning: false)
        @series = series
        # @settings = settings
        # @max_size = initial_max_size
        # @points = Points.new(indicator: self)
        # return if cloning

        # after_initialization
        # parent_series.each { |ohlc| append ohlc }
        # @points_for_cache = {}
        # @dc_period = nil
      end

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

      # def after_initialization
      #   # NoOp
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

      # # Sets the dominant cycle period for the current indicator's point
      # # @dc_period gets set before each #compute call.
      # def update_dc_period
      #   ensure_not_dominant_cycler_indicator
      #   @dc_period = current_dominant_cycle.period
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