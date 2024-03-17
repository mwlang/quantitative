# frozen_string_literal: true

module Quant
  class Indicators
    # The MESA inidicator
    class MesaPoint < IndicatorPoint
      attribute :mama, default: :input
      attribute :fama, default: :input
      attribute :dama, default: :input
      attribute :gama, default: :input
      attribute :lama, default: :input
      attribute :faga, default: :input
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
    # This version of Ehler's MAMA indicator ties into the homodyne
    # dominant cycle indicator to provide a more efficient computation
    # for this indicator.  If you're using the homodyne in all your
    # indicators for the dominant cycle, then this version is useful
    # as it avoids extra computational steps.
    class Mesa < Indicator
      def period
        dc_period
      end

      def fast_limit
        @fast_limit ||= bars_to_alpha(min_period / 2)
      end

      def slow_limit
        @slow_limit ||= bars_to_alpha(max_period)
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

      FAMA = 0.500
      GAMA = 0.950
      DAMA = 0.125
      LAMA = 0.100
      FAGA = 0.050

      def compute
        alpha = [fast_limit / delta_phase, slow_limit].max

        p0.mama = (alpha * p0.input) + ((1.0 - alpha) * p1.mama)
        p0.fama = (FAMA * alpha * p0.mama) + ((1.0 - (FAMA * alpha)) * p1.fama)
        p0.gama = (GAMA * alpha * p0.mama) + ((1.0 - (GAMA * alpha)) * p1.gama)
        p0.dama = (DAMA * alpha * p0.mama) + ((1.0 - (DAMA * alpha)) * p1.dama)
        p0.lama = (LAMA * alpha * p0.mama) + ((1.0 - (LAMA * alpha)) * p1.lama)
        p0.faga = (FAGA * alpha * p0.fama) + ((1.0 - (FAGA * alpha)) * p1.faga)

        compute_oscillator
      end

      def compute_oscillator
        p0.osc = p0.mama - p0.fama
        p0.crossed = :up if p0.osc >= 0 && p1.osc < 0
        p0.crossed = :down if p0.osc <= 0 && p1.osc > 0
      end
    end
  end
end
