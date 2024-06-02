# frozen_string_literal: true

module Quant
  module Indicators
    class RocketRsiPoint < IndicatorPoint
      attribute :hp, default: 0.0

      attribute :delta, default: 0.0
      attribute :gain, default: 0.0
      attribute :loss, default: 0.0

      attribute :gains, default: 0.0
      attribute :losses, default: 0.0
      attribute :denom, default: 0.0

      attribute :inst_rsi, default: 0.5
      attribute :rsi, default: 0.0
      attribute :crosses, default: false
    end

    class RocketRsi < Indicator
      register name: :rocket_rsi

      def quarter_period
        half_period / 2
      end

      def half_period
        (dc_period / 2) - 1
      end

      def compute
        p0.hp = two_pole_butterworth :input, previous: :hp, period: quarter_period

        lp = p(half_period)
        p0.delta = p0.hp - lp.hp
        p0.delta > 0.0 ? p0.gain = p0.delta : p0.loss = p0.delta.abs

        period_points(half_period).tap do |period_points|
          p0.gains = period_points.map(&:gain).sum
          p0.losses = period_points.map(&:loss).sum
        end

        p0.denom = p0.gains + p0.losses

        if p0.denom.zero?
          p0.inst_rsi = p1.inst_rsi
          p0.rsi = p1.rsi
        else
          p0.inst_rsi = ((p0.gains - p0.losses) / p0.denom)
          p0.rsi = fisher_transform(p0.inst_rsi).clamp(-1.0, 1.0)
        end
        p0.crosses = (p0.rsi >= 0.0 && p1.rsi < 0.0) || (p0.rsi <= 0.0 && p1.rsi > 0.0)
      end
    end
  end
end