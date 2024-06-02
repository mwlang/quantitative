# frozen_string_literal: true

module Quant
  module Indicators
    module Pivots
      # The value of X in the formula below depends on where the Close of the market is.
      # If Close = Open then X = (H + L + (C * 2))

      # If Close > Open then X = ((H * 2) + L + C)

      # If Close < Open then X = (H + (L * 2) + C)

      # R1 = X / 2 - L
      # PP = X / 4 (this is not an official DeMark number but merely a reference point based on the calculation of X)
      # S1 = X / 2 - H
      class Demark < Pivot
        register name: :demark

        def averaging_period
          min_period / 2
        end

        def x_factor
          if t0.close_price == t0.open_price
            ((2.0 * t0.close_price) + p0.avg_high + p0.avg_low)
          elsif t0.close_price > t0.open_price
            ((2.0 * p0.avg_high) + p0.avg_low + t0.close_price)
          else
            ((2.0 * p0.avg_low) + p0.avg_high + t0.close_price)
          end
        end

        def compute_value
          p0.input = x_factor
        end

        def compute_midpoint
          p0.midpoint = p0.input / 4.0
          p0.midpoint = super_smoother :midpoint, previous: :midpoint, period: averaging_period
        end

        def compute_bands
          p0.h1 = (p0.input / 2.0) - p0.avg_high
          p0.h1 = super_smoother :h1, previous: :h1, period: averaging_period

          p0.l1 = (p0.input / 2.0) - p0.avg_low
          p0.l1 = super_smoother :l1, previous: :l1, period: averaging_period
        end
      end
    end
  end
end
