# frozen_string_literal: true

module Quant
  module Mixins
    module HighPassFilters
      # HighPass Filters are “detrenders” because they attenuate low frequency components
      # One pole HighPass and SuperSmoother does not produce a zero mean because low
      # frequency spectral dilation components are “leaking” through The one pole
      # HighPass Filter response
      def two_pole_high_pass_filter(source, period:, previous:)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        alpha = period_to_alpha(period, k: 0.707)

        v1 = p0.send(source) - (2.0 * p1.send(source)) + p2.send(source)
        v2 = p1.send(previous)
        v3 = p2.send(previous)

        a = v1 * (1 - (alpha * 0.5))**2
        b = v2 * 2 * (1 - alpha)
        c = v3 * (1 - alpha)**2

        a + b - c
      end

      # alpha = (Cosine(.707* 2 * PI / 48) + Sine (.707*360 / 48) - 1) / Cosine(.707*360 / 48);
      # is the same as the following:
      # radians = Math.sqrt(2) * Math::PI / period
      # alpha = (Math.cos(radians) + Math.sin(radians) - 1) / Math.cos(radians)
      def high_pass_filter(source, period:, previous: :hp)
        Quant.experimental("This method is unproven and may be incorrect.")
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        v0 = p0.send(source)
        v1 = p1.send(previous)
        v2 = p2.send(previous)

        radians = Math.sqrt(2) * Math::PI / period
        a = Math.exp(-radians)
        b = 2 * a * Math.cos(radians)

        c2 = b
        c3 = -a**2
        c1 = (1 + c2 - c3) / 4

        (c1 * (v0 - (2 * v1) + v2)) + (c2 * v1) + (c3 * v2)
      end
    end
  end
end
