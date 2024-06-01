# frozen_string_literal: true

module Quant
  module Indicators
    module DominantCycles
      class BandPassPoint < Quant::Indicators::IndicatorPoint
        attribute :hp, default: 0.0
        attribute :bp, default: 0.0
        attribute :counter, default: 0
        attribute :period, default: :half_period
        attribute :peak, default: :half_period
        attribute :real, default: :half_period
        attribute :crosses, default: false
        attribute :direction, default: :flat
      end

      # The band-pass dominant cycle passes signals within a certain frequency
      # range, and attenuates signals outside that range.
      # The trend component of the signal is revoved, leaving only the cyclical
      # component.  Then we count number of iterations between zero crossings
      # and this is the `period` of the dominant cycle.
      class BandPass < DominantCycle
        def bandwidth
          0.75
        end

        # alpha2 = (Cosine(.25*Bandwidth*360 / Period) +
        #             Sine(.25*Bandwidth*360 / Period) - 1) / Cosine(.25*Bandwidth*360 / Period);
        # HP = (1 + alpha2 / 2)*(Close - Close[1]) + (1- alpha2)*HP[1];
        # beta = Cosine(360 / Period);
        # gamma = 1 / Cosine(360*Bandwidth / Period);
        # alpha = gamma - SquareRoot(gamma*gamma - 1);
        # BP = .5*(1 - alpha)*(HP - HP[2]) + beta*(1 + alpha)*BP[1] - alpha*BP[2];
        # If Currentbar = 1 or CurrentBar = 2 then BP = 0;

        # Peak = .991*Peak;
        # If AbsValue(BP) > If Peak <> 0 Then DC = DC[1];
        # If DC < 6 Then DC counter = counter
        # If Real Crosses Over 0 or Real Crosses Under 0 Then Begin
        #   DC = 2*counter;
        #   If 2*counter > 1.25*DC[1] Then DC = 1.25*DC[1];
        #   If 2*counter < .8*DC[1] Then DC = .8*DC[1];
        #   counter = 0;
        # End;

        def compute_high_pass
          alpha = period_to_alpha(max_period, k: 0.25 * bandwidth)
          p0.hp = (1 + alpha / 2) * (p0.input - p1.input) + (1 - alpha) * p1.hp
        end

        def compute_band_pass
          radians = deg2rad(360.0 / max_period)
          beta = Math.cos(radians)
          gamma = 1.0 / Math.cos(bandwidth * radians)
          alpha = gamma - Math.sqrt(gamma**2 - 1.0)

          a = 0.5 * (1 - alpha) * (p0.hp - p2.hp)
          b = beta * (1 + alpha) * p1.bp
          c = alpha * p2.bp
          p0.bp = a + b - c
        end

        def compute_period
          p0.peak = [0.991 * p1.peak, p0.bp.abs].max
          p0.real = p0.bp / p0.peak unless p0.peak.zero?
          p0.counter = p1.counter + 1
          p0.period = [p1.period, min_period].max.to_i
          p0.crosses = (p0.real > 0.0 && p1.real < 0.0) || (p0.real < 0.0 && p1.real > 0.0)
          if (p0.real >= 0.0 && p1.real < 0.0) || (p0.real <= 0.0 && p1.real > 0.0)
            p0.period = [2 * p0.counter, 1.25 * p1.period].min.to_i
            p0.period = [p0.period, 0.8 * p1.period].max.to_i
            p0.counter = 0
          end
          p0.direction = p0.real > (p1.real + p2.real + p3.real) / 3.0 ? :up : :down
        end

        def compute
          compute_high_pass
          compute_band_pass
          compute_period
        end
      end
    end
  end
end
