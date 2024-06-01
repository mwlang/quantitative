
module Quant
  module Indicators
    module Pivots
      class Murrey < Pivot
        def multiplier
          0.125
        end

        def compute_midpoint
          p0.input = (p0.highest - p0.lowest) * multiplier
          p0.midpoint = p0.lowest + (p0.input * 4.0)
        end

        def compute_bands
          p0.h6 = p0.midpoint + p0.input * 6.0
          p0.h5 = p0.midpoint + p0.input * 5.0
          p0.h4 = p0.midpoint + p0.input * 4.0
          p0.h3 = p0.midpoint + p0.input * 3.0
          p0.h2 = p0.midpoint + p0.input * 2.0
          p0.h1 = p0.midpoint + p0.input * 1.0

          p0.l1 = p0.midpoint - p0.input * 1.0
          p0.l2 = p0.midpoint - p0.input * 2.0
          p0.l3 = p0.midpoint - p0.input * 3.0
          p0.l4 = p0.midpoint - p0.input * 4.0
          p0.l5 = p0.midpoint - p0.input * 5.0
          p0.l6 = p0.midpoint - p0.input * 6.0
        end
      end
    end
  end
end