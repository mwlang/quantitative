# frozen_string_literal: true

module Quant
  module Mixins
    module MovingAverages
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

      # Computes the Exponential Moving Average (EMA) of the given period.
      #
      # The EMA computation is optimized to compute using just the last two
      # indicator data points and is expected to be called in each indicator's
      # `#compute` method for each iteration on the series.
      #
      # @param source [Symbol] the source of the data points to be used in the calculation.
      # @param previous [Symbol] the previous EMA value.
      # @param period [Integer] the number of elements to compute the EMA over.
      # @return [Float] the exponential moving average of the period.
      # @raise [ArgumentError] if the source is not a Symbol.
      # @example
      #   def compute
      #     p0.ema = exponential_moving_average(:close_price, period: 3)
      #   end
      #
      #   def compute
      #     p0.ema = exponential_moving_average(:close_price, previous: :ema, period: 3)
      #   end
      def exponential_moving_average(source, previous: :ema, period:)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, "previous must be a Symbol" unless previous.is_a?(Symbol)

        alpha = 2.0 / (period + 1)
        p0.send(source) * alpha + p1.send(previous) * (1.0 - alpha)
      end
      alias ema exponential_moving_average
    end
  end
end
