# frozen_string_literal: true

module Quant
  module Ticks
    class IndicatorPoints
      attr_reader :points

      def initialize(tick:)
        @tick = tick
        @points = {}
      end

      def [](indicator)
        points[indicator]
      end

      def []=(indicator, point)
        points[indicator] = point
      end
    end
  end
end
