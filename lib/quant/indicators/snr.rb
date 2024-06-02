# frozen_string_literal: true

module Quant
  module Indicators
    class SnrPoint < IndicatorPoint
      attribute :smooth, default: 0.0
      attribute :detrend, default: 0.0
      attribute :i1, default: 0.0
      attribute :q1, default: 0.0
      attribute :noise, default: 0.0
      attribute :signal, default: 0.0
      attribute :ratio, default: 0.0
      attribute :state, default: 0
    end

    class Snr < Indicator
      register name: :snr
      depends_on DominantCycles::Homodyne

      def homodyne_dominant_cycle
        series.indicators[source].dominant_cycles.homodyne
      end

      def current_dominant_cycle
        homodyne_dominant_cycle.points[t0]
      end

      def threshold
        @threshold ||= 10 * Math.log(0.5)**2
      end

      def compute_values
        current_dominant_cycle.tap do |dc|
          p0.i1 = dc.i1
          p0.q1 = dc.q1
        end
      end

      def compute_noise
        noise = (p0.input - p2.input).abs
        p0.noise = p1.noise.zero? ? noise : (0.1 * noise) + (0.9 * p1.noise)
      end

      def compute_ratio
        # p0.ratio = 0.25 * (10 * Math.log(p0.i1**2 + p0.q1**2) / Math.log(10)) + 0.75 * p1.ratio
        # ratio = .25*(10 * Log(I1*I1 + Q1*Q1)/(Range*Range))/Log(10) + 6) + .75*ratio[1]
        if p0 == p1
          p0.signal = 0.0
          p0.ratio = 1.0
        else
          p0.signal = threshold + 10.0 * (Math.log((p0.i1**2 + p0.q1**2)/(p0.noise**2)) / Math.log(10))
          p0.ratio = (0.25 * p0.signal) + (0.75 * p1.ratio)
        end
        p0.state = p0.ratio >= threshold ? 1 : 0
      end

      def compute
        compute_values
        compute_noise
        compute_ratio
      end
    end
  end
end
