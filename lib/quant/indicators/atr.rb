# frozen_string_literal: true

module Quant
  module Indicators
    class AtrPoint < IndicatorPoint
      attribute :tr, default: 0.0
      attribute :period, default: :min_period
      attribute :value, default: 0.0
      attribute :slow, default: 0.0
      attribute :fast, default: 0.0
      attribute :inst_stoch, default: 0.0
      attribute :stoch, default: 0.0
      attribute :stoch_up, default: false
      attribute :stoch_turned, default: false
      attribute :osc, default: 0.0
      attribute :crossed, default: :unchanged

      def crossed_up?
        @crossed == :up
      end

      def crossed_down?
        @crossed == :down
      end
    end

    class Atr < Indicator
      register name: :atr

      attr_reader :points

      def period
        dc_period / 2
      end

      def fast_alpha
        period_to_alpha(period)
      end

      def slow_alpha
        period_to_alpha(2 * period)
      end

      # Typically, the Average True Range (ATR) is based on 14 periods and can be calculated on an intraday, daily, weekly
      # or monthly basis. For this example, the ATR will be based on daily data. Because there must be a beginning, the first
      # TR value is simply the High minus the Low, and the first 14-day ATR is the average of the daily TR values for the
      # last 14 days. After that, Wilder sought to smooth the data by incorporating the previous period's ATR value.

      # Current ATR = [(Prior ATR x 13) + Current TR] / 14

      #   - Multiply the previous 14-day ATR by 13.
      #   - Add the most recent day's TR value.
      #   - Divide the total by 14

      def compute
        p0.period = period
        p0.tr = (t1.high_price - t0.close_price).abs

        p0.value = three_pole_super_smooth :tr, period:, previous: :value

        p0.slow = (slow_alpha * p0.value) + ((1.0 - slow_alpha) * p1.slow)
        p0.fast = (fast_alpha * p0.value) + ((1.0 - fast_alpha) * p1.fast)

        p0.inst_stoch = stochastic :value, period:
        p0.stoch = three_pole_super_smooth(:inst_stoch, previous: :stoch, period:).clamp(0, 100)
        p0.stoch_up = p0.stoch >= 70
        p0.stoch_turned = p0.stoch_up && !p1.stoch_up
        compute_oscillator
      end

      def compute_oscillator
        p0.osc = p0.value - wma(:value)
        p0.crossed = :up if p0.osc >= 0 && p1.osc < 0
        p0.crossed = :down if p0.osc <= 0 && p1.osc > 0
      end
    end
  end
end
