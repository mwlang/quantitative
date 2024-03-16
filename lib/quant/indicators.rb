# frozen_string_literal: true

require_relative "indicators_proxy"
module Quant
  # TODO: build an Indicator registry so new indicators can be added and
  #       used outside those shipped with the library.
  class Indicators < IndicatorsProxy
    def ping; indicator(Indicators::Ping) end
    def adx; indicator(Indicators::Adx) end
    def atr; indicator(Indicators::Atr) end
    def mesa; indicator(Indicators::Mesa) end
    def mama; indicator(Indicators::MAMA) end

    def dominant_cycles
      @dominant_cycles ||= Quant::DominantCycleIndicators.new(series:, source:)
    end
  end
end
