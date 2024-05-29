module Quant
  class Indicators
    class Pivots
      class Atr < Pivot
        depends_on Indicators::Atr

        def atr_point
          series.indicators[source].atr.points[t0]
        end

        def scale
          5.0
        end

        def atr_value
          atr_point.slow * scale
        end

        def compute_midpoint
          p0.midpoint = two_pole_super_smooth :input, previous: :midpoint, period: averaging_period
        end

        def compute_bands
          p0.h6 = p0.midpoint + 1.000 * atr_value
          p0.h5 = p0.midpoint + 0.786 * atr_value
          p0.h4 = p0.midpoint + 0.618 * atr_value
          p0.h3 = p0.midpoint + 0.500 * atr_value
          p0.h2 = p0.midpoint + 0.382 * atr_value
          p0.h1 = p0.midpoint + 0.236 * atr_value

          p0.l1 = p0.midpoint - 0.236 * atr_value
          p0.l2 = p0.midpoint - 0.382 * atr_value
          p0.l3 = p0.midpoint - 0.500 * atr_value
          p0.l4 = p0.midpoint - 0.618 * atr_value
          p0.l5 = p0.midpoint - 0.786 * atr_value
          p0.l6 = p0.midpoint - 1.000 * atr_value
        end
      end
    end
  end
end