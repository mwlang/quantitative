# frozen_string_literal: true

module Quant
  module Indicators
    class AtrPoint < IndicatorPoint
      attribute :tr, default: 0.0
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

    # The Average True Range refers to a technical analysis indicator that measures
    # the volatility of an asset’s or security’s price action. The ATR was introduced
    # by J. Welles Wilder in his book  “New Concepts in Technical Trading Systems” in 1978.

    # The ATR formula is “[(Prior ATR x(n-1)) + Current TR]/n” where
    # TR = ​max [(high − low), abs(high − previous close​), abs(low – previous close)].

    # ATR values are primarily calculated on 14-day periods. Also, analysts use it
    # to measure volatility for any specific duration spanning from intraday time
    # frames to larger time frames.

    # A high value of ATR implies high volatility, and a low value of ATR indicates
    # low volatility or market sideways.

    # Current ATR = [(Prior ATR x 13) + Current TR] / 14

    #   - Multiply the previous 14-day ATR by 13.
    #   - Add the most recent day's TR value.
    #   - Divide the total by 14
    #
    # This ATR is an adaptive version of the tradtional ATR based on half the
    # dominant cycle period. It uses a 3-pole super smooth filter to smooth
    # the ATR values. It also calculates the stochastic value of the ATR
    # and the oscillator value of the ATR.
    class Atr < Indicator
      register name: :atr

      attr_reader :points

      def fast_alpha
        period_to_alpha(adaptive_half_period)
      end

      def slow_alpha
        period_to_alpha(adaptive_period)
      end

      def traditional_true_range
        high_low = t0.high_price - t0.low_price
        high_prev_close = (t0.high_price - t1.close_price).abs
        low_prev_close = (t0.low_price - t1.close_price).abs

        [high_low, high_prev_close, low_prev_close].max
      end

      def compute_true_range
        p0.tr = traditional_true_range
        p0.tr = t0.high_price - (t0.high_price * 0.99) if p0.tr.zero?
        p0.value = three_pole_super_smooth :tr, period: adaptive_half_period, previous: :value
      end

      def compute
        compute_true_range

        p0.slow = ema(:value, previous: :slow, period: slow_alpha)
        p0.fast = ema(:value, previous: :fast, period: fast_alpha)

        p0.inst_stoch = stochastic :value, period: adaptive_half_period
        p0.stoch = three_pole_super_smooth(:inst_stoch, previous: :stoch, period: adaptive_half_period).clamp(0, 100)
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
