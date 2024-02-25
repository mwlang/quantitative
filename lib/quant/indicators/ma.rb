module Quant
  class Indicators
    class MaPoint < IndicatorPoint
      attribute :ss, key: "ss"
      attribute :ema, key: "ema"
      attr_accessor :ss, :ema, :osc

      def initialize_data_points
        @ss = input
        @ema = input
        @osc = nil
      end
    end

    # Moving Averages
    class Ma < Indicator
      include Quant::Mixins::Filters

      def alpha(period)
        bars_to_alpha(period)
      end

      def min_period
        8 # Quant.config.indicators.min_period
      end

      def max_period
        48 # Quant.config.indicators.max_period
      end

      def compute
        # p0.ss = super_smoother input, :ss, min_period
        p0.ema = alpha(max_period) * input + (1 - alpha(max_period)) * p1.ema
        p0.osc = p0.ss - p0.ema
      end
    end
  end
end
