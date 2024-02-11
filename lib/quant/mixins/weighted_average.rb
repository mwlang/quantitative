# frozen_string_literal: true

module Quant
  module Mixins
    module WeightedAverage
      def weighted_average(source)
        value = source.is_a?(Symbol) ? p0.send(source) : source
        [4.0 * value,
         3.0 * p1.send(source),
         2.0 * p2.send(source),
         p3.send(source),].sum / 10.0
      end

      def extended_weighted_average(source)
        value = source.is_a?(Symbol) ? p0.send(source) : source
        [7.0 * value,
         6.0 * p1.send(source),
         5.0 * p2.send(source),
         4.0 * p3.send(source),
         3.0 * prev(4).send(source),
         2.0 * prev(5).send(source),
         prev(6).send(source),].sum / 28.0
      end
    end
  end
end
