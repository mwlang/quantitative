# frozen_string_literal: true

module Quant
  module Mixins
    # Fisher Transforms
    # • Price is not a Gaussian (Bell Curve) distribution, even though many
    #   technical analysis formulas falsely assume that it is. Bell Curve tails
    #   are missing.
    #     – If $10 stock were Gaussian, it could go up or down $20
    #     – Standard deviation based indicators like Bollinger Bands
    #       and zScore make the Gaussian assumption error
    #
    # • TheFisher Transform converts almost any probability distribution
    #   in a Gaussian-like one
    #     – Expands the distribution and creates tails
    #
    # • The Inverse Fisher Transform converts almost any probability
    #   distribution into a square wave
    #     – Compresses, removes low amplitude variations
    module FisherTransform
      # inverse fisher transform
      # https://www.mql5.com/en/articles/303
      def inverse_fisher_transform(value, scale_factor: 1.0)
        r = (Math.exp(2.0 * scale_factor * value) - 1.0) / (Math.exp(2.0 * scale_factor * value) + 1.0)
        r.nan? ? 0.0 : r
      end
      alias ift inverse_fisher_transform

      def relative_fisher_transform(value, max_value:)
        max_value.zero? ? 0.0 : fisher_transform(value / max_value)
      end
      alias rft relative_fisher_transform

      # The absolute value passed must be < 1.0
      def fisher_transform(value)
        raise ArgumentError, "value (#{value}) must be between -1.0 and 1.0" unless value.abs <= 1.0

        result = 0.5 * Math.log((1.0 + value) / (1.0 - value))
        result.nan? ? 0.0 : result
      rescue Math::DomainError => e
        raise Math::DomainError, "#{e.message}: cannot take the Log of #{value}: #{(1 + value) / (1 - value)}"
      end
      alias fisher fisher_transform
      alias ft fisher_transform
    end
  end
end
