# frozen_string_literal: true

module Quant
  # {Quant::IndicatorSources} pairs a collection of {Quant::Indicators::Indicator} with an input source.
  # This allows us to only compute indicators for the sources that are referenced at run-time.
  # Any source explicitly used at run-time will have its indicator computed and only those indicators
  # will be computed.
  class IndicatorsSources
    ALL_SOURCES = [
      PRICE_SOURCES = %i[price open_price high_price low_price close_price].freeze,
      VOLUME_SOURCES = %i[volume base_volume target_volume].freeze,
      COMPUTED_SOURCES = %i[oc2 hl2 hlc3 ohlc4].freeze
    ].flatten.freeze

    attr_reader :series

    def initialize(series:)
      @series = series
      @sources = {}
    end

    def [](source)
      raise invalid_source_error(source:) unless ALL_SOURCES.include?(source)

      @sources[source] ||= IndicatorsSource.new(series:, source:)
    end

    def <<(tick)
      @sources.each_value { |indicator| indicator << tick }
    end

    ALL_SOURCES.each do |source|
      define_method(source) do
        @sources[source] ||= IndicatorsSource.new(series:, source:)
      end
    end

    def respond_to_missing?(method, *)
      oc2.respond_to?(method)
    end

    def method_missing(method_name, *args, &block)
      return super unless respond_to_missing?(method_name)

      oc2.send(method_name, *args, &block)
    end

    private

    def invalid_source_error(source:)
      raise Errors::InvalidIndicatorSource, "Invalid indicator source: #{source.inspect}"
    end
  end
end
