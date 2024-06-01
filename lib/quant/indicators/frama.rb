# frozen_string_literal: true

module Quant
  module Indicators
    class FramaPoint < IndicatorPoint
      attribute :frama, default: :input
      attribute :dimension, default: 0.0
      attribute :alpha, default: 0.0
    end

    # FRAMA (FRactal Adaptive Moving Average). A nonlinear moving average
    # is derived using the Hurst exponent. It rapidly follows significant
    # changes in price but becomes very flat in congestion zones so that
    # bad whipsaw trades can be eliminated.
    #
    # SOURCE: http://www.mesasoftware.com/papers/FRAMA.pdf
    class Frama < Indicator
      using Quant

      # The max_period is divided into two smaller, equal periods, so must be even
      def max_period
        @max_period ||= begin
          mp = super
          mp.even? ? mp : mp + 1
        end
      end

      def half_period
        max_period / 2
      end

      def compute
        pp = period_points(max_period).map(&:input)
        return if pp.size < max_period

        n3 = (pp.maximum - pp.minimum) / max_period

        ppn2 = pp.first(half_period)
        n2 = (ppn2.maximum - ppn2.minimum) / half_period

        ppn1 = pp.last(half_period)
        n1 = (ppn1.maximum - ppn1.minimum) / half_period

        p0.dimension = (Math.log(n1 + n2) - Math.log(n3)) / Math.log(2)
        p0.alpha = Math.exp(-4.6 * (p0.dimension - 1.0)).clamp(0.01, 1.0)
        p0.frama = (p0.alpha * p0.input) + ((1 - p0.alpha) * p1.frama)
      end
    end
  end
end
