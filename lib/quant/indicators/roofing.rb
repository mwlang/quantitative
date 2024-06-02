# frozen_string_literal: true

module Quant
  module Indicators
    # The ideal time to buy is when the cycle is at a trough, and the ideal time to exit a long position or to
    # sell short is when the cycle is at a peak.These conditions are flagged by the filter crossing itself
    # delayed by two bars, and are included as part of the indicator.
    class RoofingPoint < IndicatorPoint
      attribute :hp, default: 0.0
      attribute :value, default: 0.0
      attribute :peak, default: 0.0
      attribute :agc, default: 0.0
      attribute :direction, default: 0
      attribute :turned, default: false
    end

    class Roofing < Indicator
      register name: :roofing

      def low_pass_period
        dc_period
      end

      def high_pass_period
        low_pass_period * 2
      end

      # //Highpass filter cyclic components whose periods are shorter than 48 bars
      # alpha1 = (Cosine(.707*360 / HPPeriod) + Sine (.707*360 / HPPeriod) - 1) / Cosine(.707*360 / HPPeriod);
      # HP = (1 - alpha1 / 2)*(1 - alpha1 / 2)*(Close - 2*Close[1] + Close[2]) + 2*(1 - alpha1)*HP[1] - (1 - alpha1)*
      # (1 - alpha1)*HP[2];
      # //Smooth with a Super Smoother Filter from equation 3-3
      # a1 = expvalue(-1.414*3.14159 / LPPeriod);
      # b1 = 2*a1*Cosine(1.414*180 / LPPeriod);
      # c2 = b1;
      # c3 = -a1*a1;
      # c1 = 1 - c2 - c3;
      # Filt = c1*(HP + HP[1]) / 2 + c2*Filt[1] + c3*Filt[2
      def compute
        a = Math.cos(0.707 * deg2rad(360) / high_pass_period)
        b = Math.sin(0.707 * deg2rad(360) / high_pass_period)
        alpha1 = (a + b - 1) / a

        p0.hp = (1 - alpha1 / 2)**2 * (p0.input - 2 * p1.input + p2.input) + 2 * (1 - alpha1) * p1.hp - (1 - alpha1)**2 * p2.hp
        a1 = Math.exp(-1.414 * Math::PI / low_pass_period)
        c2 = 2 * a1 * Math.cos(1.414 * deg2rad(180) / low_pass_period)
        c3 = -a1**2
        c1 = 1 - c2 - c3
        p0.value = c1 * (p0.hp + p1.hp) / 2 + c2 * p1.value + c3 * p2.value
        p0.direction = p0.value > p2.value ? 1 : -1
        p0.turned = p0.direction != p2.direction
        # Peak = .991 * Peak[1];
        # If AbsValue(BP) > Peak Then Peak = AbsValue(BP); If Peak <> 0 Then Signal = BP / Peak;
        p0.peak = [p0.value.abs, 0.991 * p1.peak].max
        p0.agc = p0.peak == 0 ? 0 : p0.value / p0.peak
      end
    end
  end
end