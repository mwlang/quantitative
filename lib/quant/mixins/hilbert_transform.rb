# frozen_string_literal: true

module Quant
  module Mixins
    module HilbertTransform
      def hilbert_transform(source, period = p1.period)
        [0.0962 * p0.send(source),
         0.5769 * p2.send(source),
         -0.5769 * prev(4).send(source),
         -0.0962 * prev(6).send(source),].sum * ((0.075 * period) + 0.54)
      end
    end
  end
end
