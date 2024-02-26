# frozen_string_literal: true

module Quant
  module Mixins
    module SuperSmoother
      def two_pole_super_smooth(source, period:, previous: :ss)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        radians = Math::PI * Math.sqrt(2) / period
        a1 = Math.exp(-radians)

        coef2 = 2.0r * a1 * Math.cos(radians)
        coef3 = -a1 * a1
        coef1 = 1.0 - coef2 - coef3

        v0 = (p0.send(source) + p1.send(source))/2.0
        v1 = p2.send(previous)
        v2 = p3.send(previous)
        ((coef1 * v0) + (coef2 * v1) + (coef3 * v2)).to_f
      end
      alias super_smoother two_pole_super_smooth
      alias ss2p two_pole_super_smooth

      def three_pole_super_smooth(source, period:, previous: :ss)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        a1 = Math.exp(-Math::PI / period)
        b1 = 2 * a1 * Math.cos(Math::PI * Math.sqrt(3) / period)
        c1 = a1**2

        coef2 = b1 + c1
        coef3 = -(c1 + b1 * c1)
        coef4 = c1**2
        coef1 = 1 - coef2 - coef3 - coef4

        v0 = p0.send(source)
        v1 = p1.send(previous)
        v2 = p2.send(previous)
        v3 = p3.send(previous)

        (coef1 * v0) + (coef2 * v1) + (coef3 * v2) + (coef4 * v3)
      end
      alias ss3p three_pole_super_smooth
    end
  end
end
