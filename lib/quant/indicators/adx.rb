require_relative "indicator_point"
require_relative "indicator"

module Quant
  class Indicators
    class AdxPoint < IndicatorPoint
      attribute :dmu, default: 0.0
      attribute :dmd, default: 0.0
      attribute :dmu_ema, default: 0.0
      attribute :dmd_ema, default: 0.0
      attribute :diu, default: 0.0
      attribute :did, default: 0.0
      attribute :di, default: 0.0
      attribute :di_ema, default: 0.0
      attribute :value, default: 0.0
      attribute :inst_stoch, default: 0.0
      attribute :stoch, default: 0.0
      attribute :stoch_up, default: false
      attribute :stoch_turned, default: false
      attribute :ssf, default: 0.0
      attribute :hp, default: 0.0
    end

    class Adx < Indicator
      def alpha
        bars_to_alpha(dc_period)
      end

      def scale
        1.0
      end

      def period
        dc_period
      end

      def atr_point
        series.indicators[source].atr.points[t0]
      end

      def compute
        # To calculate the ADX, first determine the + and - directional movement, or DM.
        # The +DM and -DM are found by calculating the "up-move," or current high minus
        # the previous high, and "down-move," or current low minus the previous low.
        # If the up-move is greater than the down-move and greater than zero, the +DM equals the up-move;
        # otherwise, it equals zero. If the down-move is greater than the up-move and greater than zero,
        # the -DM equals the down-move; otherwise, it equals zero.
        dm_highs = [t0.high_price - t1.high_price, 0.0].max
        dm_lows  = [t0.low_price - t1.low_price, 0.0].max

        p0.dmu = dm_highs > dm_lows ? 0.0 : dm_highs
        p0.dmd = dm_lows > dm_highs ? 0.0 : dm_lows

        p0.dmu_ema = three_pole_super_smooth :dmu, period:, previous: :dmu_ema
        p0.dmd_ema = three_pole_super_smooth :dmd, period:, previous: :dmd_ema

        atr_value = atr_point.fast * scale
        return if atr_value == 0.0 || @points.size < period

        # The positive directional indicator, or +DI, equals 100 times the EMA of +DM divided by the ATR
        # over a given number of time periods. Welles usually used 14 periods.
        # The negative directional indicator, or -DI, equals 100 times the EMA of -DM divided by the ATR.
        p0.diu = (100.0 * p0.dmu_ema) / atr_value
        p0.did = (100.0 * p0.dmd_ema) / atr_value

        # The ADX indicator itself equals 100 times the EMA of the absolute value of (+DI minus -DI)
        # divided by (+DI plus -DI).
        delta = p0.diu + p0.did
        p0.di = (p0.diu - p1.did).abs / delta
        p0.di_ema = three_pole_super_smooth(:di, period:, previous: :di_ema).clamp(-10.0, 10.0)

        p0.value = p0.di_ema
        p0.inst_stoch = stochastic :di, period: dc_period
        p0.stoch = three_pole_super_smooth :inst_stoch, period:, previous: :stoch
      end
    end
  end
end
