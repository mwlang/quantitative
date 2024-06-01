# frozen_string_literal: true

module Quant
  module Indicators
    module DominantCycles
      # This dominant cycle indicator is based on the half period
      # that is the midpoint of the `min_period` and `max_period`
      # configured in the `Quant.config.indicators` object.
      # Effectively providing a static, arbitrarily set period.
      class HalfPeriodPoint < Quant::Indicators::IndicatorPoint
        attribute :period, default: :half_period
      end

      class HalfPeriod < DominantCycle
        def compute
          # No-Op
        end
      end
    end
  end
end
