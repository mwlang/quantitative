
module Quant
  module Indicators
    module Pivots
      class Murrey < Pivot
        register name: :murrey

        def multiplier
          0.125
        end

        def compute_midpoint
          p0.input = (p0.highest - p0.lowest) * multiplier
          p0.midpoint = p0.lowest + (p0.input * 4.0)
        end

        MURREY_SERIES = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0].freeze

        def compute_bands
          MURREY_SERIES.each_with_index do |ratio, index|
            p0[index + 1] = p0.midpoint + p0.input * ratio
            p0[-index - 1] = p0.midpoint - p0.input * ratio
          end
        end
      end
    end
  end
end