module Quant
  module Indicators
    module Pivots
      class Keltner < Pivot
        register name: :keltner
        depends_on Indicators::Atr

        def atr_point
          series.indicators[source].atr.points[t0]
        end

        def scale
          3.0
        end

        def compute_midpoint
          alpha = bars_to_alpha(min_period)
          p0.midpoint = alpha * p0.input + (1 - alpha) * p1.midpoint
        end

        KELTNER_SERIES = [0.236, 0.382, 0.500, 0.618, 0.786, 1.0].freeze

        def compute_bands
          atr_value = atr_point.value * scale

          KELTNER_SERIES.each_with_index do |ratio, index|
            offset = ratio * atr_value
            p0[index + 1] = p0.midpoint + offset
            p0[-index - 1] = p0.midpoint - offset
          end
        end
      end
    end
  end
end