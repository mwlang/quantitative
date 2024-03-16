require_relative "../indicator"

module Quant
  class Indicators
    # Dominant Cycles measure the primary cycle within a given range.  By default, the library
    # is wired to look for cycles between 10 and 48 bars.  These values can be adjusted by setting
    # the `min_period` and `max_period` configuration values in {Quant::Config}.
    #
    #    Quant.configure_indicators(min_period: 8, max_period: 32)
    #
    # The default dominant cycle kind is the `half_period` filter.  This can be adjusted by setting
    # the `dominant_cycle_kind` configuration value in {Quant::Config}.
    #
    #    Quant.configure_indicators(dominant_cycle_kind: :band_pass)
    #
    # The purpose of these indicators is to compute the dominant cycle and underpin the various
    # indicators that would otherwise be setting an arbitrary lookback period.  This makes the
    # indicators adaptive and auto-tuning to the market dynamics.  Or so the theory goes!
    class DominantCycles
      class DominantCyclePoint < Quant::Indicators::IndicatorPoint
        attribute :smooth, default: 0.0
        attribute :detrend, default: 0.0
        attribute :inst_period, default: :min_period
        attribute :period, key: "p", default: nil # intentially nil! (see: compute_period)
        attribute :smooth_period, key: "sp", default: :min_period
        attribute :mean_period, key: "mp", default: :min_period
        attribute :ddd, default: 0.0
        attribute :q1, default: 0.0
        attribute :q2, default: 0.0
        attribute :i1, default: 0.0
        attribute :i2, default: 0.0
        attribute :ji, default: 0.0
        attribute :jq, default: 0.0
        attribute :re, default: 0.0
        attribute :im, default: 0.0
        attribute :phase, default: 0.0
        attribute :phase_sum, key: "ps", default: 0.0
        attribute :delta_phase, default: 0.0
        attribute :accumulator_phase, default: 0.0
        attribute :real_part, default: 0.0
        attribute :imag_part, default: 0.0
      end

      class DominantCycle < Indicators::Indicator
        def points_class
          Object.const_get "Quant::Indicators::DominantCycles::#{indicator_name}Point"
        rescue NameError
          DominantCyclePoint
        end

        # constrain between min_period and max_period bars
        def constrain_period_bars
          p0.inst_period = p0.inst_period.clamp(min_period, max_period)
        end

        attr_reader :points

        # constrain magnitude of change in phase
        def constrain_period_magnitude_change
          p0.inst_period = [1.5 * p1.inst_period, p0.inst_period].min
          p0.inst_period = [0.67 * p1.inst_period, p0.inst_period].max
        end

        # amplitude correction using previous period value
        def compute_smooth_period
          p0.inst_period = (0.2 * p0.inst_period) + (0.8 * p1.inst_period)
          p0.smooth_period = (0.33333 * p0.inst_period) + (0.666667 * p1.smooth_period)
        end

        def compute_mean_period
          ss_period = super_smoother(:smooth_period, previous: :mean_period, period: micro_period)
          p0.mean_period = ss_period.clamp(min_period, max_period)
        end

        def dominant_cycle_period
          [p0.period.to_i, min_period].max
        end

        def period_points(max_period)
          extent = [values.size, max_period].min
          values[-extent, extent]
        end

        def compute
          compute_input_data_points
          compute_quadrature_components
          compute_period
          compute_smooth_period
          compute_mean_period
          compute_phase
        end

        def compute_input_data_points
          p0.smooth = wma :input
          p0.detrend = hilbert_transform :smooth, period: p1.inst_period
        end

        # NOTE: The phase lag of q1 and `i1 is (360 * 7 / Period - 90)` degrees
        # where Period is the dominant cycle period.
        def compute_quadrature_components
          # { Compute Inphase and Quadrature components }
          p0.q1 = hilbert_transform :detrend, period: p1.inst_period
          p0.i1 = p3.detrend

          # { Advance the phase of I1 and Q1 by 90 degrees }
          p0.ji = hilbert_transform :i1, period: p1.inst_period
          p0.jq = hilbert_transform :q1, period: p1.inst_period

          # { Smooth the I and Q components before applying the discriminator }
          p0.i2 = (0.2 * (p0.i1 - p0.jq)) + 0.8 * (p1.i2 || (p0.i1 - p0.jq))
          p0.q2 = (0.2 * (p0.q1 + p0.ji)) + 0.8 * (p1.q2 || (p0.q1 + p0.ji))
        end

        def compute_period
          raise NotImplementedError
        end

        def compute_phase
          raise "must compute period before calling!" unless p0.period

          period_points(dominant_cycle_period).map(&:smooth).each_with_index do |smooth, index|
            radians = deg2rad((1 + index) * 360.0 / dominant_cycle_period)
            p0.real_part += smooth * Math.sin(radians)
            p0.imag_part += smooth * Math.cos(radians)
          end

          if p0.imag_part.zero?
            p0.phase = 90.0 * (p0.real_part.positive? ? 1 : 0)
          else
            radians = deg2rad(p0.real_part / p0.imag_part)
            p0.phase = rad2deg(Math.atan(radians))
          end
          p0.phase += 90
          # { Compensate for one bar lag of the Weighted Moving Average }
          p0.phase += (360.0 / p0.inst_period)

          p0.phase += 180.0 if p0.imag_part < 0.0
          p0.phase -= 360.0 if p0.phase > 315.0
          p0.delta_phase = [1.0, p1.phase - p0.phase].max
        end
      end
    end
  end
end