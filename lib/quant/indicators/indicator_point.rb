# frozen_string_literal: true

module Quant
  class Indicators
    class IndicatorPoint
      include Quant::Attributes

      attr_reader :tick
      attribute :source, key: "src"
      attribute :input, key: "in"

      def initialize(tick:, source:)
        @tick = tick
        @source = source
        @input = @tick.send(source)
        initialize_data_points
      end

      def initialize_data_points
        # No-Op - Override in subclass if needed.
      end
    end
  end
end
