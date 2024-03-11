module Quant
  module Statistics
    class Correlation
      attr_accessor :length, :sx, :sy, :sxx, :sxy, :syy

      def initialize
        @length = 0.0
        @sx = 0.0
        @sy = 0.0
        @sxx = 0.0
        @sxy = 0.0
        @syy = 0.0
      end

      def add(x, y)
        @length += 1
        @sx += x
        @sy += y
        @sxx += x * x
        @sxy += x * y
        @syy += y * y
      end

      def devisor
        value = (length * sxx - sx**2) * (length * syy - sy**2)
        value.zero? ? 1.0 : value
      end

      def coefficient
        (length * sxy - sx * sy) / Math.sqrt(devisor)
      rescue Math::DomainError
        0.0
      end
    end
  end
end

