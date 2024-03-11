# frozen_string_literal: true

module Quant
  class IndicatorsSources
    def initialize(series:)
      @series = series
      @indicator_sources = {}
    end

    def <<(tick)
      @indicator_sources.each_value { |indicator| indicator << tick }
    end

    def oc2
      @indicator_sources[:oc2] ||= Indicators.new(series: @series, source: :oc2)
    end
  end
end
