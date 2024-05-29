# frozen_string_literal: true

module Quant
  class Indicators
    class Pivots
      class Classic < Pivot
        def compute_midpoint
          p0.midpoint = super_smoother :input, previous: :midpoint, period: averaging_period
        end

        def compute_bands
          p0.h1 = p0.midpoint * 2.0 - p0.avg_low
          p0.l1 = p0.midpoint * 2.0 - p0.avg_high

          p0.h2 = p0.midpoint + p0.avg_range
          p0.l2 = p0.midpoint - p0.avg_range

          p0.h3 = p0.midpoint + 2.0 * p0.avg_range
          p0.l3 = p0.midpoint - 2.0 * p0.avg_range
        end
      end
    end
  end
end
