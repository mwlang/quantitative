# frozen_string_literal: true

module Quant
  module Indicators
    module DominantCycles
      # Homodyne means the signal is multiplied by itself. More precisely,
      # we want to multiply the signal of the current bar with the complex
      # value of the signal one bar ago
      class Homodyne < DominantCycle
        def compute_period
          p0.re = (p0.i2 * p1.i2) + (p0.q2 * p1.q2)
          p0.im = (p0.i2 * p1.q2) - (p0.q2 * p1.i2)

          p0.re = (0.2 * p0.re) + (0.8 * p1.re)
          p0.im = (0.2 * p0.im) + (0.8 * p1.im)

          p0.inst_period = 360.0 / rad2deg(Math.atan(p0.im / p0.re)) if (p0.im != 0) && (p0.re != 0)

          constrain_period_magnitude_change
          constrain_period_bars
          p0.mean_period = super_smoother :inst_period, previous: :mean_period, period: max_period
          p0.period = p0.mean_period.round(0).to_i
        end
      end
    end
  end
end
