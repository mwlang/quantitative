# frozen_string_literal: true

module Quant
  module Mixins
    module HighPassFilters
      # HighPass Filters are “detrenders” because they attenuate low frequency components
      # One pole HighPass and SuperSmoother does not produce a zero mean because low
      # frequency spectral dilation components are “leaking” through The one pole
      # HighPass Filter response
      def two_pole_high_pass_filter(source, prev_source, min_period, max_period = nil)
        raise "source must be a symbol" unless source.is_a?(Symbol)
        return p0.send(source) if p0 == p2

        max_period ||= min_period * 2
        (min_period * Math.sqrt(2))
        max_radians = 2.0 * Math::PI / (max_period * Math.sqrt(2))

        v1 = p0.send(source) - (2.0 * p1.send(source)) + p2.send(source)
        v2 = p1.send(prev_source)
        v3 = p2.send(prev_source)

        alpha = period_to_alpha(max_radians)

        a = (1 - (alpha * 0.5))**2 * v1
        b = 2 * (1 - alpha) * v2
        c = (1 - alpha)**2 * v3

        a + b - c
      end

      # alpha = (Cosine(.707* 2 * PI / 48) + Sine (.707*360 / 48) - 1) / Cosine(.707*360 / 48);
      # is the same as the following:
      # radians = Math.sqrt(2) * Math::PI / period
      # alpha = (Math.cos(radians) + Math.sin(radians) - 1) / Math.cos(radians)
      def high_pass_filter(source, period:, previous: :hp)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        v0 = p0.send(source)
        return v0 if p3 == p0

        v1 = p1.send(source)
        v2 = p2.send(source)

        radians = Math.sqrt(2) * Math::PI / period
        a = Math.exp(-radians)
        b = 2 * a * Math.cos(radians)

        c2 = b
        c3 = -a**2
        c1 = (1 + c2 - c3) / 4

        (c1 * (v0 - (2 * v1) + v2)) + (c2 * p1.hp) + (c3 * p2.hp)
      end
    end
  end
end
