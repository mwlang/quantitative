# frozen_string_literal: true

module Quant
  module Mixins
    module WeightedMovingAverage
      using Quant
      # Computes the Weighted Moving Average (WMA) of the series, using the four most recent data points.
      #
      # @param source [Symbol] the source of the data points to be used in the calculation.
      # @return [Float] the weighted average of the series.
      # @raise [ArgumentError] if the source is not a Symbol.
      # @example
      #   p0.wma = weighted_average(:close_price)
      def weighted_moving_average(source)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        [4.0 * p0.send(source),
         3.0 * p1.send(source),
         2.0 * p2.send(source),
         p3.send(source)].sum / 10.0
      end
      alias wma weighted_moving_average

      # Computes the Weighted Moving Average (WMA) of the series, using the seven most recent data points.
      #
      # @param source [Symbol] the source of the data points to be used in the calculation.
      # @return [Float] the weighted average of the series.
      # @raise [ArgumentError] if the source is not a Symbol.
      # @example
      #   p0.wma = weighted_average(:close_price)
      def extended_weighted_moving_average(source)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

        [7.0 * p0.send(source),
         6.0 * p1.send(source),
         5.0 * p2.send(source),
         4.0 * p3.send(source),
         3.0 * p(4).send(source),
         2.0 * p(5).send(source),
         p(6).send(source)].sum / 28.0
      end
      alias ewma extended_weighted_moving_average
    end
  end
end
