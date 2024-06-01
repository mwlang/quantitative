# frozen_string_literal: true

module Quant
  module Indicators
    class CciPoint < IndicatorPoint
      attribute :hp, default: 0.0
      attribute :real, default: 0.0
      attribute :imag, default: 0.0
      attribute :angle, default: 0.0
      attribute :state, default: 0
    end

    # Correlation Cycle Index
    # The very definition of a trend mode and a cycle mode makes it simple
    # to create a state variable that identifies the market state. If the
    # state is zero, the market is in a cycle mode. If the state is +1 the
    # market is in a trend up. If the state is -1 the market is in a trend down.
    #
    # SOURCE: https://www.mesasoftware.com/papers/CORRELATION%20AS%20A%20CYCLE%20INDICATOR.pdf
    class Cci < Indicator
      def max_period
        [min_period, dc_period].max
      end

      def compute_correlations
        corr_real = Statistics::Correlation.new
        corr_imag = Statistics::Correlation.new
        arc = 2.0 * Math::PI / max_period.to_f
        (0...max_period).each do |period|
          radians = arc * period
          prev_hp = p(period).hp
          corr_real.add(prev_hp, Math.cos(radians))
          corr_imag.add(prev_hp, -Math.sin(radians))
        end
        p0.real = corr_real.coefficient
        p0.imag = corr_imag.coefficient
      end

      def compute_angle
        # Compute the angle as an arctangent and resolve the quadrant
        p0.angle = 90 + rad2deg(Math.atan(p0.real / p0.imag))
        p0.angle -= 180 if p0.imag > 0

        # Do not allow the rate change of angle to go negative
        p0.angle = p1.angle if (p0.angle < p1.angle) && (p1.angle - p0.angle) < 270
      end

      def compute_state
        return unless (p0.angle - p1.angle).abs < 9

        p0.state = p0.angle < 0 ? -1 : 1
      end

      def compute
        p0.hp = two_pole_butterworth :input, previous: :hp, period: min_period

        compute_correlations
        compute_angle
        compute_state
      end
    end
  end
end
