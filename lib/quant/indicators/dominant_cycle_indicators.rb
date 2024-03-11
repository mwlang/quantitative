module Quant
  class DominantCycleIndicators < IndicatorsProxy
    def acr; indicator(Indicators::DominantCycles::Acr) end
    def band_pass; indicator(Indicators::DominantCycles::BandPass) end
    def homodyne; indicator(Indicators::DominantCycles::Homodyne) end

    def differential; indicator(Indicators::DominantCycles::Differential) end
    def phase_accumulator; indicator(Indicators::DominantCycles::PhaseAccumulator) end
  end
end
