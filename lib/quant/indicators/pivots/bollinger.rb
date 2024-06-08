# frozen_string_literal: true

module Quant
  module Indicators
    module Pivots
      class Bollinger < Pivot
        register name: :bollinger

        using Quant

        def compute_midpoint
          values = period_points(adaptive_half_period).map(&:input)
          alpha = bars_to_alpha(adaptive_half_period)

          p0.midpoint = alpha * values.mean + (1 - alpha) * p1.midpoint
          p0.std_dev = values.standard_deviation(p0.midpoint)
        end

        BOLLINGER_SERIES = [1.0, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0].freeze

        def compute_bands
          BOLLINGER_SERIES.each_with_index do |ratio, index|
            p0[index + 1] = p0.midpoint + ratio * p0.std_dev
            p0[-index - 1] = p0.midpoint - ratio * p0.std_dev
          end
        end
      end
    end
  end
end
