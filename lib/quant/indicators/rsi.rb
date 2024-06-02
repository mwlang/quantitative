# frozen_string_literal: true

module Quant
  module Indicators
    class RsiPoint < IndicatorPoint
      attribute :hp, default: 0.0
      attribute :filter, default: 0.0

      attribute :delta, default: 0.0
      attribute :gain, default: 0.0
      attribute :loss, default: 0.0

      attribute :gains, default: 0.0
      attribute :losses, default: 0.0
      attribute :denom, default: 0.0

      attribute :inst_rsi, default: 0.0
      attribute :rsi, default: 0.0
    end

    # The Relative Strength Index (RSI) is a momentum oscillator that measures the
    # speed and change of price movements.  This RSI indicator is adaptive and
    # uses the half-period of the dominant cycle to calculate the RSI.
    # It is further smoothed by an exponential moving average of the last three bars
    # (or whatever the micro_period is set to).
    #
    # The RSI oscillates between 0 and 1.  Traditionally, and in this implementation,
    # the RSI is considered overbought when above 0.7 and oversold when below 0.3.
    class Rsi < Indicator
      register name: :rsi

      def quarter_period
        half_period / 2
      end

      def half_period
        (dc_period / 2) - 1
      end

      def compute
        # The High Pass filter is half the dominant cycle period while the
        # Low Pass Filter (super smoother) is the quarter dominant cycle period.
        p0.hp = high_pass_filter :input, period: half_period
        p0.filter = ema :hp, previous: :filter, period: quarter_period

        lp = p(half_period)
        p0.delta = p0.filter - lp.filter
        p0.delta > 0.0 ? p0.gain = p0.delta : p0.loss = p0.delta.abs

        period_points(half_period).tap do |period_points|
          p0.gains = period_points.map(&:gain).sum
          p0.losses = period_points.map(&:loss).sum
        end

        p0.denom = p0.gains + p0.losses

        if p0.denom > 0.0
          p0.inst_rsi = (p0.gains / p0.denom)
          p0.rsi = ema :inst_rsi, previous: :rsi, period: micro_period
        else
          p0.inst_rsi = 0.5
          p0.rsi = 0.5
        end
      end
    end
  end
end