# frozen_string_literal: true

module Quant
  class PivotsSource
    def initialize(indicator_source:)
      @indicator_source = indicator_source
    end

    def atr; indicator(Indicators::Pivots::Atr) end
    def bollinger; indicator(Indicators::Pivots::Bollinger) end
    def camarilla; indicator(Indicators::Pivots::Camarilla) end
    def classic; indicator(Indicators::Pivots::Classic) end
    def demark; indicator(Indicators::Pivots::Demark) end
    def donchian; indicator(Indicators::Pivots::Donchian) end
    def fibbonacci; indicator(Indicators::Pivots::Fibbonacci) end
    def guppy; indicator(Indicators::Pivots::Guppy) end
    def keltner; indicator(Indicators::Pivots::Keltner) end
    def murrey; indicator(Indicators::Pivots::Murrey) end
    def traditional; indicator(Indicators::Pivots::Traditional) end
    def woodie; indicator(Indicators::Pivots::Woodie) end

    private

    def indicator(indicator_class)
      @indicator_source[indicator_class]
    end
  end
end
