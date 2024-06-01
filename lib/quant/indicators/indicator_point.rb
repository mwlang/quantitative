# frozen_string_literal: true

module Quant
  module Indicators
    class IndicatorPoint
      include Quant::Attributes
      extend Forwardable

      attr_reader :indicator, :tick

      attribute :source, key: "src"
      attribute :input, key: "in"

      def initialize(indicator:, tick:, source:)
        @indicator = indicator
        @tick = tick
        @source = source
        @input = @tick.send(source)
        initialize_data_points
      end

      def_delegator :indicator, :series
      def_delegator :indicator, :min_period
      def_delegator :indicator, :max_period
      def_delegator :indicator, :half_period
      def_delegator :indicator, :micro_period
      def_delegator :indicator, :dominant_cycle_kind
      def_delegator :indicator, :pivot_kind

      def initialize_data_points
        # No-Op - Override in subclass if needed.
      end
    end
  end
end
