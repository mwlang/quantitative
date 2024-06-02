# frozen_string_literal: true

module Quant
  module Indicators
    # A simple point used primarily to test the indicator system in unit tests.
    # It has a simple computation that just sets the pong value to the input value
    # and increments the compute_count by 1 each time compute is called.
    # Sometimes you just gotta play ping pong to win.
    class PingPoint < IndicatorPoint
      attribute :pong
      attribute :compute_count, default: 0
    end

    # A simple idicator used primarily to test the indicator system
    class Ping < Indicator
      register name: :ping

      def compute
        p0.pong = input
        p0.compute_count += 1
      end
    end
  end
end
