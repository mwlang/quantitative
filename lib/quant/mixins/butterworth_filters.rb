# frozen_string_literal: true

module Quant
  module Mixins
    module ButterworthFilters
      def two_pole_butterworth(source, period:, previous: :bw)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        v0 = p0.send(source)

        v1 = 0.5 * (v0 + p1.send(source))
        v2 = p1.send(previous)
        v3 = p2.send(previous)

        radians = Math.sqrt(2) * Math::PI / period
        a = Math.exp(-radians)
        b = 2 * a * Math.cos(radians)

        c2 = b
        c3 = -a**2
        c1 = 1.0 - c2 - c3

        (c1 * v1) + (c2 * v2) + (c3 * v3)
      end

      def three_pole_butterworth(source, period:, previous: :bw)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        v0 = p0.send(source)
        v1 = p1.send(previous)
        v2 = p2.send(previous)
        v3 = p3.send(previous)

        radians = Math.sqrt(3) * Math::PI / period
        a = Math.exp(-radians)
        b = 2 * a * Math.cos(radians)
        c = a**2

        d4 = c**2
        d3 = -(c + (b * c))
        d2 = b + c
        d1 = 1.0 - d2 - d3 - d4

        (d1 * v0) + (d2 * v1) + (d3 * v2) + (d4 * v3)
      end
    end
  end
end
