# frozen_string_literal: true

module Quant
  class IndicatorsSources
    def initialize(series:)
      @series = series
      @indicator_sources = {}
    end

    def new_indicator(indicator)
      @indicator_sources[indicator.source] ||= Indicators.new(series: @series, source: indicator.source)
    end

    def [](source)
      return @indicator_sources[source] if @indicator_sources.key?(source)

      raise Quant::Errors::InvalidIndicatorSource, "Invalid source, #{source.inspect}."
    end

    def <<(tick)
      @indicator_sources.each_value { |indicator| indicator << tick }
    end

    def oc2
      @indicator_sources[:oc2] ||= Indicators.new(series: @series, source: :oc2)
    end
  end
end
