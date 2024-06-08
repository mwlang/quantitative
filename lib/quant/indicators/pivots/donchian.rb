# frozen_string_literal: true

module Quant
  module Indicators
    module Pivots
      class Donchian < Pivot
        register name: :donchian

        def compute_midpoint
          p0.midpoint = (p0.high_price + p0.low_price) * 0.5
        end

        def compute_bands
          period_points(micro_period).tap do |period_points|
            p0.l1 = period_points.map(&:low_price).min
            p0.h1 = period_points.map(&:high_price).max
          end

          period_points(min_period).tap do |period_points|
            p0.l2 = period_points.map(&:low_price).min
            p0.h2 = period_points.map(&:high_price).max
          end

          period_points(half_period).tap do |period_points|
            p0.l3 = period_points.map(&:low_price).min
            p0.h3 = period_points.map(&:high_price).max
          end

          period_points(max_period).tap do |period_points|
            p0.l4 = period_points.map(&:low_price).min
            p0.h4 = period_points.map(&:high_price).max
          end
        end
      end
    end
  end
end
