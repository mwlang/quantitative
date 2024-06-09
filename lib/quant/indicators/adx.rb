# frozen_string_literal: true

module Quant
  module Indicators
    class AdxPoint < IndicatorPoint
      attribute :dmu, default: 0.0
      attribute :dmd, default: 0.0

      attribute :adaptive_dmu, default: 0.0
      attribute :adaptive_dmd, default: 0.0
      attribute :adaptive_diu, default: 0.0
      attribute :adaptive_did, default: 0.0
      attribute :adaptive_di, default: 0.0
      attribute :value, default: 0.0

      attribute :full_dmu, default: 0.0
      attribute :full_dmd, default: 0.0
      attribute :full_diu, default: 0.0
      attribute :full_did, default: 0.0
      attribute :full_di, default: 0.0
      attribute :full, default: 0.0

      attribute :slow_dmu, default: 0.0
      attribute :slow_dmd, default: 0.0
      attribute :slow_diu, default: 0.0
      attribute :slow_did, default: 0.0
      attribute :slow_di, default: 0.0
      attribute :slow, default: 0.0

      attribute :traditional_dmu, default: 0.0
      attribute :traditional_dmd, default: 0.0
      attribute :traditional_diu, default: 0.0
      attribute :traditional_did, default: 0.0
      attribute :traditional_di, default: 0.0
      attribute :traditional, default: 0.0

      attribute :inst_stoch, default: 0.0
      attribute :stoch, default: 0.0
      attribute :stoch_up, default: false
      attribute :stoch_turned, default: false
    end

    # The Average Directional Index (ADX) is a technical indicator that measures
    # the strength of a trend in the market. It's calculated using a moving
    # average of price fluctuations over a specific period of time, and is
    # based on two other indicators: the Positive Directional Indicator (+DI)
    # and the Negative Directional Indicator (-DI):
    #
    # 1. Calculate the period's True Range (TR), +DI, and -DI
    # 2. Calculate the Smoothed Moving Average (SMA) of the TR, +DI, and -DI
    # 3. Compute the Directional Movement Index (DX) using the +DI and -DI SMA
    # 4. Calculate the ADX by taking the SMA of the DX
    #
    # The formula for ADX is:
    #     ADX = 100 × ( +DI minus -DI)  / (+DI plus -DI) / ATR
    #
    # Welles usually used 14 periods and this indicator takes that to be functionally
    # equivalent to half the dominant cycle period.
    class Adx < Indicator
      register name: :adx
      depends_on Indicators::Atr

      def traditional_period
        atr_indicator.traditional_period
      end

      def full_period
        atr_indicator.full_period
      end

      def slow_period
        atr_indicator.slow_period
      end

      def atr_indicator
        @atr_indicator ||= series.indicators[source].atr
      end

      def atr_point
        atr_indicator.points[t0]
      end

      # To calculate the ADX, first determine the + and - directional movement, or DM.
      # The +DM and -DM are found by calculating the "up-move," or current high minus
      # the previous high, and "down-move," or current low minus the previous low.
      # If the up-move is greater than the down-move and greater than zero, the +DM equals the up-move;
      # otherwise, it equals zero. If the down-move is greater than the up-move and greater than zero,
      # the -DM equals the down-move; otherwise, it equals zero.
      def compute_directional_movement
        dm_highs = [t0.high_price - t1.high_price, 0.0].max
        dm_lows  = [t0.low_price - t1.low_price, 0.0].max

        p0.dmu = dm_highs > dm_lows ? 0.0 : dm_highs
        p0.dmd = dm_lows > dm_highs ? 0.0 : dm_lows
      end

      def compute_adaptive_period
        p0.adaptive_dmu = three_pole_super_smooth(:dmu, previous: :adaptive_dmu, period: adaptive_half_period)
        p0.adaptive_dmd = three_pole_super_smooth(:dmd, previous: :adaptive_dmd, period: adaptive_half_period)

        atr_value = atr_point.value
        return if atr_value == 0.0 || points.size < adaptive_half_period

        p0.adaptive_diu = (100.0 * p0.adaptive_dmu) / atr_value
        p0.adaptive_did = (100.0 * p0.adaptive_dmd) / atr_value

        p0.adaptive_di = (p0.adaptive_diu - p1.adaptive_did).abs / (p0.adaptive_diu + p0.adaptive_did)
        p0.value = three_pole_super_smooth(:adaptive_di, previous: :value, period: adaptive_half_period).clamp(-10.0, 10.0)
      end

      def compute_full_period
        p0.full_dmu = three_pole_super_smooth(:dmu, previous: :full_dmu, period: full_period)
        p0.full_dmd = three_pole_super_smooth(:dmd, previous: :full_dmd, period: full_period)

        atr_value = atr_point.full
        return if atr_value == 0.0 || points.size < full_period

        p0.full_diu = (100.0 * p0.full_dmu) / atr_value
        p0.full_did = (100.0 * p0.full_dmd) / atr_value

        p0.full_di = (p0.full_diu - p1.full_did).abs / (p0.full_diu + p0.full_did)
        p0.full = three_pole_super_smooth(:full_di, previous: :full, period: full_period).clamp(-10.0, 10.0)
      end

      def compute_slow_period
        p0.slow_dmu = three_pole_super_smooth(:dmu, previous: :slow_dmu, period: slow_period)
        p0.slow_dmd = three_pole_super_smooth(:dmd, previous: :slow_dmd, period: slow_period)

        atr_value = atr_point.slow
        return if atr_value == 0.0 || points.size < slow_period

        p0.slow_diu = (100.0 * p0.slow_dmu) / atr_value
        p0.slow_did = (100.0 * p0.slow_dmd) / atr_value

        p0.slow_di = (p0.slow_diu - p1.slow_did).abs / (p0.slow_diu + p0.slow_did)
        p0.slow = three_pole_super_smooth(:slow_di, previous: :slow, period: slow_period).clamp(-10.0, 10.0)
      end

      def compute_traditional_period
        p0.traditional_dmu = three_pole_super_smooth(:dmu, previous: :traditional_dmu, period: traditional_period)
        p0.traditional_dmd = three_pole_super_smooth(:dmd, previous: :traditional_dmd, period: traditional_period)

        atr_value = atr_point.traditional
        return if atr_value == 0.0 || points.size < traditional_period

        p0.traditional_diu = (100.0 * p0.traditional_dmu) / atr_value
        p0.traditional_did = (100.0 * p0.traditional_dmd) / atr_value

        p0.traditional_di = (p0.traditional_diu - p1.traditional_did).abs / (p0.traditional_diu + p0.traditional_did)
        p0.traditional = three_pole_super_smooth(:traditional_di, previous: :traditional, period: traditional_period).clamp(-10.0, 10.0)
      end

      def compute_stochastic
        p0.inst_stoch = stochastic(:adaptive_di, period: adaptive_half_period)
        p0.stoch = three_pole_super_smooth(:inst_stoch, previous: :stoch, period: adaptive_half_period)
      end

      def compute
        compute_directional_movement
        compute_adaptive_period
        compute_full_period
        compute_slow_period
        compute_traditional_period
        compute_stochastic
      end
    end
  end
end
