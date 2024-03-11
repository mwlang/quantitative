require_relative "dominant_cycle"

module Quant
  class Indicators
    class DominantCycles
      # The phase accumulation method of computing the dominant cycle is perhaps
      # the easiest to comprehend. In this technique, we measure the phase
      # at each sample by taking the arctangent of the ratio of the quadrature
      # component to the in-phase component. A delta phase is generated by
      # taking the difference of the phase between successive samples.
      # At each sam- ple we can then look backwards, adding up the delta
      # phases.  When the sum of the delta phases reaches 360 degrees,
      # we must have passed through one full cycle, on average.  The process
      # is repeated for each new sample.
      #
      # The phase accumulation method of cycle measurement always uses one
      # full cycle’s worth of historical data. This is both an advantage
      # and a disadvantage.  The advantage is the lag in obtaining the answer
      # scales directly with the cycle period.  That is, the measurement of
      # a short cycle period has less lag than the measurement of a longer
      # cycle period. However, the number of samples used in making the
      # measurement means the averaging period is variable with cycle period.
      # Longer averaging reduces the noise level compared to the signal.
      # Therefore, shorter cycle periods necessarily have a higher output
      # signal-to-noise ratio.
      class PhaseAccumulator < DominantCycle
        def compute_period
          p0.i1 = 0.15 * p0.i1 + 0.85 * p1.i1
          p0.q1 = 0.15 * p0.q1 + 0.85 * p1.q1

          p0.accumulator_phase = Math.atan(p0.q1 / p0.i1) unless p0.i1.zero?

          case
          when p0.i1 < 0 && p0.q1 > 0 then p0.accumulator_phase = 180.0 - p0.accumulator_phase
          when p0.i1 < 0 && p0.q1 < 0 then p0.accumulator_phase = 180.0 + p0.accumulator_phase
          when p0.i1 > 0 && p0.q1 < 0 then p0.accumulator_phase = 360.0 - p0.accumulator_phase
          end

          p0.delta_phase = p1.accumulator_phase - p0.accumulator_phase
          if p1.accumulator_phase < 90.0 && p0.accumulator_phase > 270.0
            p0.delta_phase = 360.0 + p1.accumulator_phase - p0.accumulator_phase
          end

          p0.delta_phase = p0.delta_phase.clamp(min_period, max_period)

          p0.inst_period = p1.inst_period
          period_points(max_period).each_with_index do |prev, index|
            p0.phase_sum += prev.delta_phase
            if p0.phase_sum > 360.0
              p0.inst_period = index
              break
            end
          end
          p0.period = (0.25 * p0.inst_period + 0.75 * p1.inst_period).round(0)
        end
      end
    end
  end
end
