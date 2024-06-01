# frozen_string_literal: true

module Quant
  module Mixins
    module MovingAverages
      include WeightedMovingAverage
      include SimpleMovingAverage
      include ExponentialMovingAverage
    end
  end
end
