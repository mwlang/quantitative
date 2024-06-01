# frozen_string_literal: true

module Quant
  module Indicators
    module Pivots
      # Camarilla pivot point calculations are rather straightforward. We need to
      # input the previous day’s open, high, low and close. The formulas for each
      # resistance and support level are:
      #
      # R4 = Close + (High – Low) * 1.1/2
      # R3 = Close + (High – Low) * 1.1/4
      # R2 = Close + (High – Low) * 1.1/6
      # R1 = Close + (High – Low) * 1.1/12
      # S1 = Close – (High – Low) * 1.1/12
      # S2 = Close – (High – Low) * 1.1/6
      # S3 = Close – (High – Low) * 1.1/4
      # S4 = Close – (High – Low) * 1.1/2
      #
      # The calculation for further resistance and support levels varies from this
      # norm. These levels can come into play during strong trend moves, so it’s
      # important to understand how to identify them. For example, R5, R6, S5 and S6
      # are calculated as follows:
      #
      # R5 = R4 + 1.168 * (R4 – R3)
      # R6 = (High/Low) * Close
      #
      # S5 = S4 – 1.168 * (S3 – S4)
      # S6 = Close – (R6 – Close)
      class Camarilla < Pivot
        def multiplier
          1.1
        end

        def compute_midpoint
          p0.midpoint = t0.close_price
        end

        def compute_bands
          mp_plus_range = p0.midpoint + p0.range
          mp_minus_range = p0.midpoint - p0.range

          p0.h4 = mp_plus_range * (1.1 / 2.0)
          p0.h3 = mp_plus_range * (1.1 / 4.0)
          p0.h2 = mp_plus_range * (1.1 / 6.0)
          p0.h1 = mp_plus_range * (1.1 / 12.0)

          p0.l1 = mp_minus_range * (1.1 / 12.0)
          p0.l2 = mp_minus_range * (1.1 / 6.0)
          p0.l3 = mp_minus_range * (1.1 / 4.0)
          p0.l4 = mp_minus_range * (1.1 / 2.0)

          p0.h5 = p0.h4 + 1.168 * (p0.h4 - p0.h3)
          p0.h6 = p0.midpoint * (p0.high_price / p0.low_price)

          p0.l5 = p0.l4 - 1.168 * (p0.l3 - p0.l4)
          p0.l6 = p0.midpoint - (p0.h6 - p0.midpoint)
        end
      end
    end
  end
end
