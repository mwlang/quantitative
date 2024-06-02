# frozen_string_literal: true

module Quant
  class PivotsSource
    def initialize(indicator_source:)
      @indicator_source = indicator_source
      indicator_source.define_indicator_accessors(indicator_source: self)
    end

    private

    def indicator(indicator_class)
      @indicator_source[indicator_class]
    end
  end
end
