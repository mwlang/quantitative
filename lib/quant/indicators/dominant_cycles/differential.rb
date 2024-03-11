module Quant
  class Indicators
    class DominantCycles
      # The Dual Differentiator algorithm computes the phase angle from the analytic signal as the arctangent of
      # the ratio of the imaginary component to the real compo- nent. Further, the angular frequency is defined
      # as the rate change of phase. We can use these facts to derive the cycle period.
      class Differential < DominantCycle
        def compute_period
          p0.ddd = (p0.q2 * (p0.i2 - p1.i2)) - (p0.i2 * (p0.q2 - p1.q2))
          p0.inst_period = p0.ddd > 0.01 ? 6.2832 * (p0.i2**2 + p0.q2**2) / p0.ddd : 0.0

          constrain_period_magnitude_change
          constrain_period_bars
          p0.period = p0.inst_period.round(0).to_i
        end
      end
    end
  end
end