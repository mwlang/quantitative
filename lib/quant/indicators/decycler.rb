# frozen_string_literal: true

module Quant
  class Indicators
    # The decycler oscillator can be useful for determining the transition be- tween uptrends and downtrends by the crossing of the zero
    # line. Alternatively, the changes of slope of the decycler oscillator are easier to identify than the changes in slope of the
    # original decycler. Optimum cutoff periods can easily be found by experimentation.
    #
    # 1. A decycler filter functions the same as a low-pass filter.
    # 2. A decycler filter is created by subtracting the output of a high-pass filter from the input, thereby removing the
    #    high-frequency components by cancellation.
    # 3. A decycler filter has very low lag.
    # 4. A decycler oscillator is created by subtracting the output of a high-pass filter having a shorter cutoff period from the
    #    output of another high-pass filter having a longer cutoff period.
    # 5. A decycler oscillator shows transitions between uptrends and down-trends at the zero crossings.
    class DecyclerPoint < IndicatorPoint
      attr_accessor :decycle, :hp1, :hp2, :osc, :peak, :agc, :ift

      def to_h
        {
          "dc" => decycle,
          "hp1" => hp1,
          "hp2" => hp2,
          "osc" => osc,
        }
      end

      def initialize_data_points(indicator:)
        @decycle = oc2
        @hp1 = 0.0
        @hp2 = 0.0
        @osc = 0.0
        @peak = 0.0
        @agc = 0.0
      end
    end

    class Decycler < Indicator
      def max_period
        dc_period
      end

      def min_period
        settings.min_period
      end

      def compute_decycler
        alpha = period_to_alpha(max_period)
        p0.decycle = (alpha / 2) * (p0.oc2 + p1.oc2) + (1.0 - alpha) * p1.decycle
      end

      # alpha1 = (Cosine(.707*360 / HPPeriod1) + Sine (.707*360 / HPPeriod1) - 1) / Cosine(.707*360 / HPPeriod1);
      # HP1 = (1 - alpha1 / 2)*(1 - alpha1 / 2)*(Close - 2*Close[1] + Close[2]) + 2*(1 - alpha1)*HP1[1] - (1 - alpha1)*(1 - alpha1)*HP1[2];
      def compute_hp(period, hp)
        radians = deg2rad(360)
        c = Math.cos(0.707 * radians / period)
        s = Math.sin(0.707 * radians / period)
        alpha = (c + s - 1) / c
        (1 - alpha / 2)**2 * (p0.oc2 - 2 * p1.oc2 + p2.oc2) + 2 * (1 - alpha) * p1.send(hp) - (1 - alpha) * (1 - alpha) * p2.send(hp)
      end

      def compute_oscillator
        p0.hp1 = compute_hp(min_period, :hp1)
        p0.hp2 = compute_hp(max_period, :hp2)
        p0.osc = p0.hp2 - p0.hp1
      end

      def compute_agc
        p0.peak = [p0.osc.abs, 0.991 * p1.peak].max
        p0.agc = p0.peak.zero? ? p0.osc : p0.osc / p0.peak
      end

      def compute_ift
        p0.ift = ift(p0.agc, 5.0)
      end

      def compute
        compute_decycler
        compute_oscillator
        compute_agc
        compute_ift
      end
    end
  end
end
