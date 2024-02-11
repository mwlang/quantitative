# frozen_string_literal: true

module Quant
  module Mixins
    module Stochastic
      def stochastic(source, period = max_period)
        stoch_period = [points.size, period.to_i].min
        return 0.0 if stoch_period < 1

        subset = points[-stoch_period, stoch_period].map{ |p| p.send(source) }
        ll = subset.min
        hh = subset.max

        v0 = points[-1].send(source)
        (hh - ll).zero? ? 0.0 : 100.0 * (v0 - ll) / (hh - ll)
      end

      # module Fields
      #   @[JSON::Field(key: "ish")]
      #   property inst_stoch : Float64 = 0.0
      #   @[JSON::Field(key: "sh")]
      #   property stoch : Float64 = 0.0
      #   @[JSON::Field(key: "su")]
      #   property stoch_up : Bool = false
      #   @[JSON::Field(key: "st")]
      #   property stoch_turned : Bool = false
      # end
    end
  end
end
