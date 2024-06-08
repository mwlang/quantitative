module Quant
  module Indicators
    module Pivots
      class Fibbonacci < Pivot
        register name: :fibbonacci

        FIBBONACCI_SERIES = [0.146, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0, 1.146].freeze

        def compute_bands
          period_points(adaptive_period).tap do |period_points|
            highest = period_points.map(&:high_price).max
            lowest = period_points.map(&:low_price).min
            p0.range = highest - lowest
            p0.midpoint = (highest + lowest) * 0.5
          end

          FIBBONACCI_SERIES.each_with_index do |ratio, index|
            p0[index + 1] = p0.midpoint + ratio * p0.range
            p0[-index - 1] = p0.midpoint - ratio * p0.range
          end
        end
      end
    end
  end
end