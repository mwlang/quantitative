# frozen_string_literal: true

module Quant
  module Mixins
    module ExponentialMovingAverage
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
      def exponential_moving_average(source, period:, previous: :ema)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, "previous must be a Symbol" unless previous.is_a?(Symbol)

        alpha = bars_to_alpha(period)
        (p0.send(source) * alpha) + (p1.send(previous) * (1.0 - alpha))
      end
      alias ema exponential_moving_average
    end
  end
end
