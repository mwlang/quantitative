module Quant
  class Indicators
    class MamaPoint < IndicatorPoint
      attribute :smooth, default: 0.0
      attribute :detrend, default: 0.0
      attribute :re, default: 0.0
      attribute :im, default: 0.0
      attribute :i1, default: 0.0
      attribute :q1, default: 0.0
      attribute :ji, default: 0.0
      attribute :jq, default: 0.0
      attribute :i2, default: 0.0
      attribute :q2, default: 0.0
      attribute :period, default: :min_period
      attribute :smooth_period, default: :min_period
      attribute :mama, default: :input
      attribute :fama, default: :input
      attribute :gama, default: :input
      attribute :dama, default: :input
      attribute :lama, default: :input
      attribute :faga, default: :input
      attribute :phase, default: 0.0
      attribute :delta_phase, default: 0.0
      attribute :osc, default: 0.0
      attribute :crossed, default: :unchanged

      def crossed_up?
        @crossed == :up
      end

      def crossed_down?
        @crossed == :down
      end
    end

    # https://www.mesasoftware.com/papers/MAMA.pdf
    # MESA Adaptive Moving Average (MAMA) adapts to price movement in an
    # entirely new and unique way. The adapation is based on the rate change
    # of phase as measured by the Hilbert Transform Discriminator.
    #
    # This version of Ehler's MAMA indicator duplicates the computations
    # present in the homodyne version of the dominant cycle indicator.
    # Use this version of the indicator when you're using a different
    # dominant cycle indicator other than the homodyne for the rest
    # of your indicators.
    class Mama < Indicator
      # constrain between 6 and 50 bars
      def constrain_period_bars
        p0.period = p0.period.clamp(min_period, max_period)
      end

      # constrain magnitude of change in phase
      def constrain_period_magnitude_change
        p0.period = [1.5 * p1.period, p0.period].min
        p0.period = [0.67 * p1.period, p0.period].max
      end

      # amplitude correction using previous period value
      def compute_smooth_period
        p0.period = ((0.2 * p0.period) + (0.8 * p1.period)).round
        p0.smooth_period = ((0.33333 * p0.period) + (0.666667 * p1.smooth_period)).round
      end

      def homodyne_discriminator
        p0.re = (p0.i2 * p1.i2) + (p0.q2 * p1.q2)
        p0.im = (p0.i2 * p1.q2) - (p0.q2 * p1.i2)

        p0.re = (0.2 * p0.re) + (0.8 * p1.re)
        p0.im = (0.2 * p0.im) + (0.8 * p1.im)

        p0.period = 360.0 / rad2deg(Math.atan(p0.im / p0.re)) if (p0.im != 0) && (p0.re != 0)

        constrain_period_magnitude_change
        constrain_period_bars
        compute_smooth_period
      end

      def compute_dominant_cycle
        p0.smooth = wma :input
        p0.detrend = hilbert_transform :smooth, period: p1.period

        # { Compute Inphase and Quadrature components }
        p0.q1 = hilbert_transform :detrend, period: p1.period
        p0.i1 = p3.detrend

        # { Advance the phase of I1 and Q1 by 90 degrees }
        p0.ji = hilbert_transform :i1, period: p1.period
        p0.jq = hilbert_transform :q1, period: p1.period

        # { Smooth the I and Q components before applying the discriminator }
        p0.i2 = (0.2 * (p0.i1 - p0.jq)) + 0.8 * (p1.i2 || (p0.i1 - p0.jq))
        p0.q2 = (0.2 * (p0.q1 + p0.ji)) + 0.8 * (p1.q2 || (p0.q1 + p0.ji))

        homodyne_discriminator
      end

      def fast_limit
        @fast_limit ||= bars_to_alpha(min_period / 2)
      end

      def slow_limit
        @slow_limit ||= bars_to_alpha(max_period)
      end

      def compute_dominant_cycle_phase
        p0.delta_phase = p1.phase - p0.phase
        p0.delta_phase = 1.0 if p0.delta_phase < 1.0
      end

      FAMA = 0.500
      GAMA = 0.950
      DAMA = 0.125
      LAMA = 0.100
      FAGA = 0.050

      def compute_moving_averages
        alpha = [fast_limit / p0.delta_phase, slow_limit].max
        p0.mama = (alpha * p0.input) + ((1.0 - alpha) * p1.mama)

        p0.fama = (FAMA * alpha * p0.mama) + ((1.0 - (FAMA * alpha)) * p1.fama)
        p0.gama = (GAMA * alpha * p0.mama) + ((1.0 - (GAMA * alpha)) * p1.gama)
        p0.dama = (DAMA * alpha * p0.mama) + ((1.0 - (DAMA * alpha)) * p1.dama)
        p0.lama = (LAMA * alpha * p0.mama) + ((1.0 - (LAMA * alpha)) * p1.lama)
        p0.faga = (FAGA * alpha * p0.fama) + ((1.0 - (FAGA * alpha)) * p1.faga)
      end

      def compute_oscillator
        p0.osc = p0.mama - p0.fama
        p0.crossed = :up if p0.osc >= 0 && p1.osc < 0
        p0.crossed = :down if p0.osc <= 0 && p1.osc > 0
      end

      def compute
        compute_dominant_cycle
        compute_dominant_cycle_phase
        compute_moving_averages
        compute_oscillator
      end
    end
  end
end
