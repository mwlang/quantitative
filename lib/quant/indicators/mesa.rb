module Quant
  class Indicators
    class MesaPoint < IndicatorPoint
      attribute :ss, default: 0.0
      attribute :mama, default: :input
      attribute :fama, default: :input
      attribute :dama, default: :input
      attribute :gama, default: :input
      attribute :lama, default: :input
      attribute :faga, default: :input
      attribute :osc, default: 0.0
      attribute :osc_up, default: false
      attribute :inst_stoch, default: 0.0
      attribute :stoch, default: 0.0
      attribute :stoch_up, default: false
      attribute :stoch_turned, default: false

      def fama_up?
        mama > fama
      end

      def dama_up?
        mama > dama
      end
    end

    # https://www.mesasoftware.com/papers/PredictiveIndicators.pdf
    class Mesa < Indicator
      def period_to_alpha(period)
        dc_period / (period + 1)
      end

      def alpha_to_period(alpha)
        (dc_period - alpha) / alpha
      end

      def fast_limit
        period_to_alpha alpha_to_period(0.5)
      end

      def slow_limit
        period_to_alpha alpha_to_period(0.05)
      end

      def homodyne_dominant_cycle
        series.indicators[source].dominant_cycles.homodyne
      end

      def current_dominant_cycle
        homodyne_dominant_cycle.points[t0]
      end

      def delta_phase
        current_dominant_cycle.delta_phase
      end

      def compute
        p0.ss = three_pole_super_smooth :input, previous: :ss, period: dc_period
        alpha = [fast_limit / delta_phase, slow_limit].max

        p0.mama = (alpha * p0.input) + ((1 - alpha) * p1.mama)
        p0.fama = (0.5 * alpha * p0.mama) + ((1 - (0.5 * alpha)) * p1.fama)
        p0.gama = (0.95 * alpha * p0.mama) + ((1 - (0.95 * alpha)) * p1.gama)
        p0.dama = (0.125 * alpha * p0.mama) + ((1 - (0.125 * alpha)) * p1.dama)
        p0.lama = (0.1 * alpha * p0.mama) + ((1 - (0.1 * alpha)) * p1.lama)
        p0.faga = (0.05 * alpha * p0.fama) + ((1 - (0.05 * alpha)) * p1.faga)

        p0.osc = p0.mama - p0.fama
        p0.osc_up = p0.osc >= wma(:osc)

        p0.inst_stoch = stochastic :osc, period: dc_period
        p0.stoch = three_pole_super_smooth(:inst_stoch, previous: :stoch, period: dc_period).clamp(0, 100)
      end
    end
  end
end
