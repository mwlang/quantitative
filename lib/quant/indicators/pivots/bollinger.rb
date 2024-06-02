# frozen_string_literal: true

module Quant
  module Indicators
    module Pivots
      class Bollinger < Pivot
        register name: :bollinger

        using Quant

        def compute_midpoint
          values = period_points(half_period).map(&:input)
          alpha = bars_to_alpha(half_period)

          p0.midpoint = alpha * values.mean + (1 - alpha) * p1.midpoint
          p0.std_dev = values.standard_deviation(p0.midpoint)
        end

        def compute_bands
          p0.h1 = p0.midpoint + p0.std_dev * 1.0
          p0.l1 = p0.midpoint - p0.std_dev * 1.0

          p0.h2 = p0.midpoint + p0.std_dev * 1.5
          p0.l2 = p0.midpoint - p0.std_dev * 1.5

          p0.h3 = p0.midpoint + p0.std_dev * 1.75
          p0.l3 = p0.midpoint - p0.std_dev * 1.75

          p0.h4 = p0.midpoint + p0.std_dev * 2.0
          p0.l4 = p0.midpoint - p0.std_dev * 2.0

          p0.h5 = p0.midpoint + p0.std_dev * 2.25
          p0.l5 = p0.midpoint - p0.std_dev * 2.25

          p0.h6 = p0.midpoint + p0.std_dev * 2.5
          p0.l6 = p0.midpoint - p0.std_dev * 2.5

          p0.h7 = p0.midpoint + p0.std_dev * 2.75
          p0.l7 = p0.midpoint - p0.std_dev * 2.75

          p0.h8 = p0.midpoint + p0.std_dev * 3.0
          p0.l8 = p0.midpoint - p0.std_dev * 3.0
        end
      end
    end
  end
end
