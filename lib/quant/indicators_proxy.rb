# frozen_string_literal: true

module Quant
  class IndicatorsProxy
    attr_reader :series, :source, :indicators

    def initialize(series:, source:)
      @series = series
      @source = source
      @indicators = {}
    end

    def indicator(indicator_class)
      indicators[indicator_class] ||= indicator_class.new(series: series, source: source)
    end

    def <<(tick)
      indicators.each_value { |indicator| indicator << tick }
    end

    def ma; indicator(Indicators::Ma) end
    def ping; indicator(Indicators::Ping) end
  end
end
