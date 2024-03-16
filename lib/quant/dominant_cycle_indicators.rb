
require_relative 'indicators_proxy'

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
  class DominantCycleIndicators < IndicatorsProxy
    # Auto-Correlation Reversals is a method of computing the dominant cycle
    # by correlating the data stream with itself delayed by a lag.
    def acr; indicator(Indicators::DominantCycles::Acr) end

    # The band-pass dominant cycle passes signals within a certain frequency
    # range, and attenuates signals outside that range.
    # The trend component of the signal is removed, leaving only the cyclical
    # component.  Then we count number of iterations between zero crossings
    # and this is the `period` of the dominant cycle.
    def band_pass; indicator(Indicators::DominantCycles::BandPass) end

    # Homodyne means the signal is multiplied by itself. More precisely,
    # we want to multiply the signal of the current bar with the complex
    # value of the signal one bar ago
    def homodyne; indicator(Indicators::DominantCycles::Homodyne) end

    # The Dual Differentiator algorithm computes the phase angle from the
    # analytic signal as the arctangent of the ratio of the imaginary
    # component to the real component. Further, the angular frequency
    # is defined as the rate change of phase. We can use these facts to
    # derive the cycle period.
    def differential; indicator(Indicators::DominantCycles::Differential) end

    # The phase accumulation method of computing the dominant cycle measures
    # the phase at each sample by taking the arctangent of the ratio of the
    # quadrature component to the in-phase component.  The phase is then
    # accumulated and the period is derived from the phase.
    def phase_accumulator; indicator(Indicators::DominantCycles::PhaseAccumulator) end

    # Static, arbitrarily set period.
    def half_period; indicator(Indicators::DominantCycles::HalfPeriod) end
  end
end
