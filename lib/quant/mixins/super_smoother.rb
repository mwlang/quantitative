# frozen_string_literal: true

module Quant
  module Mixins
    module SuperSmoother
      def two_pole_super_smooth(source, period:, previous: :ss)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        radians = Math.sqrt(2) * Math::PI / period
        a1 = Math.exp(-radians)

        c3 = -a1**2
        c2 = 2.0 * a1 * Math.cos(radians)
        c1 = 1.0 - c2 - c3

        v1 = (p0.send(source) + p1.send(source)) * 0.5
        v2 = p2.send(previous)
        v3 = p3.send(previous)

        (c1 * v1) + (c2 * v2) + (c3 * v3)
      end

      alias super_smoother two_pole_super_smooth
      alias ss2p two_pole_super_smooth

      def three_pole_super_smooth(source, period:, previous: :ss)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        radians = Math::PI / period
        a1 = Math.exp(-radians)
        b1 = 2 * a1 * Math.cos(Math.sqrt(3) * radians)
        c1 = a1**2

        c4 = c1**2
        c3 = -(c1 + b1 * c1)
        c2 = b1 + c1
        c1 = 1 - c2 - c3 - c4

        v0 = p0.send(source)
        v1 = p1.send(previous)
        v2 = p2.send(previous)
        v3 = p3.send(previous)

        (c1 * v0) + (c2 * v1) + (c3 * v2) + (c4 * v3)
      end
      alias ss3p three_pole_super_smooth
    end
  end
end
