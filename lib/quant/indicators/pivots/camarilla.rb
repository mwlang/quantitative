# frozen_string_literal: true

module Quant
  module Indicators
    module Pivots
      # Camarilla pivot point calculations are rather straightforward. We need to
      # input the previous day’s open, high, low and close. The formulas for each
      # resistance and support level are:
      #
      # R4 = Closing + ((High -Low) x 1.5000)
      # R3 = Closing + ((High -Low) x 1.2500)
      # R2 = Closing + ((High -Low) x 1.1666)
      # R1 = Closing + ((High -Low x 1.0833)
      # PP = (High + Low + Closing) / 3
      # S1 = Closing – ((High -Low) x 1.0833)
      # S2 = Closing – ((High -Low) x 1.1666)
      # S3 = Closing – ((High -Low) x 1.2500)
      # S4 = Closing – ((High-Low) x 1.5000)
      #
      # R5 = R4 + 1.168 * (R4 – R3)
      # R6 = (High/Low) * Close
      # S5 = S4 – 1.168 * (S3 – S4)
      # S6 = Close – (R6 – Close)
      #
      # The calculation for further resistance and support levels varies from this
      # norm. These levels can come into play during strong trend moves, so it’s
      # important to understand how to identify them. For example, R5, R6, S5 and S6
      # are calculated as follows:
      #
      # source: https://tradingstrategyguides.com/camarilla-pivot-trading-strategy/
      class Camarilla < Pivot
        register name: :camarilla

        def compute_midpoint
          p0.midpoint = t0.hlc3
        end

        def compute_bands
          p0.h1 = t0.close_price + p0.range * 1.083
          p0.l1 = t0.close_price - p0.range * 1.083

          p0.h2 = t0.close_price + p0.range * 1.167
          p0.l2 = t0.close_price - p0.range * 1.167

          p0.h3 = t0.close_price + p0.range * 1.250
          p0.l3 = t0.close_price - p0.range * 1.250

          p0.h4 = t0.close_price + p0.range * 1.500
          p0.l4 = t0.close_price - p0.range * 1.500

          p0.h5 = p0.h4 + 1.68 * (p0.h4 - p0.h3)
          p0.l5 = p0.l4 - 1.68 * (p0.l3 - p0.l4)

          p0.h6 = (t0.high_price / t0.low_price) * t0.close_price
          p0.l6 = t0.close_price - (p0.h6 - t0.close_price)
        end
      end
    end
  end
end
