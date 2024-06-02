module Quant
  module Indicators
    module Pivots
      class Guppy < Pivot
        register name: :guppy

        def guppy_ema(period, band)
          return p0.input unless p1[band]

          alpha = bars_to_alpha(period)
          alpha * p0.input + (1 - alpha) * p1[band]
        end

        def compute_midpoint
          p0.midpoint = guppy_ema(3, 0)
        end

        # The short-term MAs are typically set at 3, 5, 8, 10, 12, and 15 periods. The
        # longer-term MAs are typically set at 30, 35, 40, 45, 50, and 60.
        def compute
          p0[1] = guppy_ema(5,  1)
          p0[2] = guppy_ema(8,  2)
          p0[3] = guppy_ema(10, 3)
          p0[4] = guppy_ema(12, 4)
          p0[5] = guppy_ema(15, 5)
          p0[6] = guppy_ema(20, 6)
          p0[7] = guppy_ema(25, 7)

          p0[-1] = guppy_ema(30, -1)
          p0[-2] = guppy_ema(35, -2)
          p0[-3] = guppy_ema(40, -3)
          p0[-4] = guppy_ema(45, -4)
          p0[-5] = guppy_ema(50, -5)
          p0[-6] = guppy_ema(60, -6)
          p0[-7] = guppy_ema(120, -7)
          p0[-8] = guppy_ema(200, -8)
        end
      end
    end
  end
end