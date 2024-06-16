# frozen_string_literal: true

module Quant
  class PivotsSource
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
