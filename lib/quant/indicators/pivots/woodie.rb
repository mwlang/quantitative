# frozen_string_literal: true

module Quant
  module Indicators
    module Pivots
      # One of the key differences in calculating Woodie's Pivot Point to other pivot
      # points is that the current session's open price is used in the PP formula with
      # the previous session's high and low. At the time-of-day that we calculate the
      # pivot points on this site in our Daily Notes we do not have the opening price
      # so we use the Classic formula for the Pivot Point and vary the R3 and R4
      # formula as per Woodie's formulas.

      # Formulas:
      #   R4 = R3 + RANGE
      #   R3 = H + 2 * (PP - L) (same as: R1 + RANGE)
      #   R2 = PP + RANGE
      #   R1 = (2 * PP) - LOW

      #   PP = (HIGH + LOW + (TODAY'S OPEN * 2)) / 4
      #   S1 = (2 * PP) - HIGH
      #   S2 = PP - RANGE
      #   S3 = L - 2 * (H - PP) (same as: S1 - RANGE)
      #   S4 = S3 - RANGE
      class Woodie < Pivot
        register name: :woodie

        def compute_value
          p0.input = (t1.high_price + t1.low_price + 2.0 * t0.open_price) / 4.0
        end

        def compute_bands
          Quant.experimental("Woodie appears erratic, is unproven and may be incorrect.")

          #   R1 = (2 * PP) - LOW
          p0.h1 = 2.0 * p0.midpoint - t1.low_price

          #   R2 = PP + RANGE
          p0.h2 = p0.midpoint + p0.range

          #   R3 = H + 2 * (PP - L) (same as: R1 + RANGE)
          p0.h3 = t1.high_price + 2.0 * (p0.midpoint - t1.low_price)

          #   R4 = R3 + RANGE
          p0.h4 = p0.h3 + p0.range

          #   S1 = (2 * PP) - HIGH
          p0.l1 = 2.0 * p0.midpoint - t1.high_price

          #   S2 = PP - RANGE
          p0.l2 = p0.midpoint - p0.range

          #   S3 = L - 2 * (H - PP) (same as: S1 - RANGE)
          p0.l3 = t1.low_price - 2.0 * (t1.high_price - p0.midpoint)

          #   S4 = S3 - RANGE
          p0.l4 = p0.l3 - p0.range
        end
      end
    end
  end
end