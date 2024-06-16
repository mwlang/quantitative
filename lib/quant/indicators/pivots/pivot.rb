module Quant
  module Indicators
    module Pivots
      class PivotPoint < IndicatorPoint
        attribute :avg_high, default: :high_price
        attribute :highest, default: :input

        attribute :avg_low, default: :low_price
        attribute :lowest, default: :input

        attribute :range, default: 0.0
        attribute :avg_range, default: 0.0
        attribute :std_dev, default: 0.0

        def bands
          @bands ||= { 0 => input }
        end

        def [](band)
          bands[band]
        end

        def []=(band, value)
          bands[band] = value
        end

        def key?(band)
          bands.key?(band)
        end

        def midpoint
          bands[0]
        end
        alias :h0 :midpoint
        alias :l0 :midpoint

        def midpoint=(value)
          bands[0] = value
        end
        alias :h0= :midpoint=
        alias :l0= :midpoint=

        (1..8).each do |band|
          define_method("h#{band}") { bands[band] }
          define_method("h#{band}=") { |value| bands[band] = value }

          define_method("l#{band}") { bands[-band] }
          define_method("l#{band}=") { |value| bands[-band] = value }
        end
      end

      class Pivot < Indicator
        def points_class
          Quant::Indicators::Pivots::PivotPoint
        end

        def band?(band)
          p0.key?(band)
        end

        def period
          adaptive_period
        end

        def averaging_period
          min_period
        end

        def period_midpoints
          period_points(period).map(&:midpoint)
        end

        def midpoint_at_input
          p0.input
        end

        def smoothed_average_midpoint
          three_pole_super_smooth :input, previous: :midpoint, period: averaging_period
        end

        def compute
          compute_extents
          compute_value
          compute_midpoint
          compute_bands
        end

        def compute_midpoint
          p0.midpoint = p0.input
        end

        def compute_value
          # No-op -- override in subclasses
        end

        def compute_bands
          # No-op -- override in subclasses
        end

        def compute_extents
          period_midpoints.tap do |midpoints|
            p0.highest = midpoints.max
            p0.lowest = midpoints.min
            p0.range = p0.high_price - p0.low_price
            p0.avg_low = three_pole_super_smooth(:low_price, previous: :avg_low, period: averaging_period)
            p0.avg_high = three_pole_super_smooth(:high_price, previous: :avg_high, period: averaging_period)
            p0.avg_range = three_pole_super_smooth(:range, previous: :avg_range, period: averaging_period)
          end
        end
      end
    end
  end
end