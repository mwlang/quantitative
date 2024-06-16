
module Quant
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
  class DominantCyclesSource
    def initialize(indicators_source:)
      @indicators_source = indicators_source
      indicators_source.define_indicator_accessors(indicators_source: self)
    end

    private

    def indicator(indicator_class)
      @indicators_source[indicator_class]
    end
  end
end
