# frozen_string_literal: true

require_relative "weighted_moving_average"
require_relative "simple_moving_average"
require_relative "exponential_moving_average"
module Quant
  module Mixins
    module MovingAverages
      include WeightedMovingAverage
      include SimpleMovingAverage
      include ExponentialMovingAverage
    end
  end
end
