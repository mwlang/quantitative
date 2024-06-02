module Quant
  module Indicators
    module Pivots
      class Fibbonacci < Pivot
        register name: :fibbonacci

        def averaging_period
          half_period
        end

        def fibbonacci_series
          [0.146, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0, 1.146]
        end

        def compute_bands
          fibbonacci_series.each_with_index do |ratio, index|
            p0[index + 1] = p0.midpoint + ratio * p0.avg_range
            p0[-index - 1] = p0.midpoint - ratio * p0.avg_range
          end
        end
      end
    end
  end
end