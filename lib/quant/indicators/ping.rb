module Quant
  class Indicators
    class PingPoint < IndicatorPoint
      attribute :pong
      attribute :compute_count, default: 0
    end

    # A simple idicator used primarily to test the indicator system
    class Ping < Indicator
      def compute
        p0.pong = input
        p0.compute_count += 1
      end
    end
  end
end
