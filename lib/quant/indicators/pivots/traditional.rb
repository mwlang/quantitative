module Quant
  class Indicators
    class Pivots
      class Traditional < Pivot
        def multiplier
          2.0
        end

        # Pivot Point (PP) = (High + Low + Close) / 3
        def compute_midpoint
          p0.midpoint = p0.input
        end

        def compute_bands
          # Third Resistance (R3) = High + 2 × (PP - Low)
          p0.h3 = p0.high_price + (multiplier * (p0.midpoint - p0.low_price))

          # Second Resistance (R2) = PP + (High - Low)
          p0.h2 = p0.midpoint + p0.range

          # First Resistance (R1) = (2 × PP) - Low
          p0.h1 = p0.midpoint * multiplier - p0.low_price

          # First Support (S1) = (2 × PP) - High
          p0.l1 = p0.midpoint * multiplier - p0.high_price

          # Second Support (S2) = PP - (High - Low)
          p0.l2 = p0.midpoint - p0.range

          # Third Support (S3) = Low - 2 × (High - PP)
          p0.l3 = p0.low_price - (multiplier * (p0.high_price - p0.midpoint))
        end
      end
    end
  end
end