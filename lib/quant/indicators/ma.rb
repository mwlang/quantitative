module Quant
  class Indicators
    class MaPoint < IndicatorPoint
      attr_accessor :ss, :ema, :osc

      def to_h
        {
          "ss" => ss,
          "ema" => delta_phase,
          "osc" => osc
        }
      end

      def initialize_data_points(indicator:)
        @ss = oc2
        @ema = oc2
        @osc = nil
      end
    end

    # Moving Averages
    class Ma < Indicator
      def self.indicator_key
        "ma"
      end

      def alpha(period)
        bars_to_alpha(period)
      end

      def min_period
        settings.min_period
      end

      def period
        settings.max_period
      end

      def compute
        p0.ss = super_smoother p0.oc2, :ss, min_period
        p0.ema = alpha(period) * p0.oc2 + (1 - alpha(period)) * p1.ema
        p0.osc = p0.ss - p0.ema
      end
    end
  end
end