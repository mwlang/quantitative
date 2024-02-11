# frozen_string_literal: true

module Quant
  module Mixins
    # Fisher Transforms
    # • Price is not a Gaussian (Bell Curve) distribution, even though many technical analysis formulas
    #   falsely assume that it is. Bell Curve tails are missing.
    #   – If $10 stock were Gaussian, it could go up or down $20 – Standard deviation based indicators like Bollinger Bands
    #   and zScore make the Gaussian assumption error
    # • TheFisher Transform converts almost any probability distribution in a Gaussian-like one
    #   – Expands the distribution and creates tails
    # • The Inverse Fisher Transform converts almost any probability distribution into a square wave
    #   – Compresses, removes low amplitude variations
    module FisherTransform
      # inverse fisher transform
      # https://www.mql5.com/en/articles/303
      def ift(value, scale_factor = 1.0)
        r = (Math.exp(2.0 * scale_factor * value) - 1.0) / (Math.exp(2.0 * scale_factor * value) + 1.0)
        r.nan? ? 0.0 : r
      end

      # def fisher_transform(value, max_value)
      #   return 0.0 if max_value.zero?
      #   x = (value / max_value).abs
      #   r = 0.5 * Math.log((1 + x) / (1 - x))
      #   r.nan? ? 0.0 : r
      # end

      # The absolute value passed must be < 1.0
      def fisher_transform(value)
        r = 0.5 * Math.log((1.0 + value) / (1.0 - value))
        r.nan? ? 0.0 : r
      rescue Math::DomainError => e
        raise "value #{value}: #{(1 + value) / (1 - value)}, e: #{e}"
      end
    end
  end
end
