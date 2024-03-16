# frozen_string_literal: true

module Quant
  module Mixins
    module Stochastic
      using Quant

      # The Stochastic Oscillator is a momentum indicator that compares a particular
      # closing price of a security to a range of its prices over a certain
      # period of time. It was developed by George C. Lane in the 1950s.

      # The main idea behind the Stochastic Oscillator is that closing
      # prices should close near the same direction as the current trend.
      # In a market trending up, prices will likely close near their
      # high, and in a market trending down, prices close near their low.
      def stochastic(source, period:)
        subset = values.last(period).map{ |p| p.send(source) }

        lowest, highest = subset.minimum.to_f, subset.maximum.to_f
        return 0.0 if (highest - lowest).zero?

        100.0 * (subset[-1] - lowest) / (highest - lowest)
      end
    end
  end
end
