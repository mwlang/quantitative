# frozen_string_literal: true

module Quant
  class Indicators
    class IndicatorPoint
      extend Forwardable

      attr_reader :tick, :source

      def initialize(tick:, source:)
        @tick = tick
        @source = @tick.send(source)
      end

      def volume
        @tick.base_volume
      end

      def timestamp
        @tick.close_timestamp
      end

      def initialize_data_points(indicator:)
        # NoOp
      end

      def to_h
        raise NotImplementedError
      end

      def to_json(*args)
        Oj.dump(to_h, *args)
      end
    end
  end
end
