# frozen_string_literal: true

module Quant
  module Mixins
    module SimpleMovingAverage
      using Quant

      # Computes the Simple Moving Average (SMA) of the given period.
      #
      # @param source [Symbol] the source of the data points to be used in the calculation.
      # @param period [Integer] the number of elements to compute the SMA over.
      # @return [Float] the simple moving average of the period.
      def simple_moving_average(source, period:)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        values.last(period).map { |value| value.send(source) }.mean
      end
      alias sma simple_moving_average
    end
  end
end
