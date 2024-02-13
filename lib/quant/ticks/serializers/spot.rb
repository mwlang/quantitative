# frozen_string_literal: true

module Quant
  module Ticks
    module Serializers
      class Spot < Tick
        # Returns a +Quant::Ticks::Tick+ from a valid JSON +String+.
        # @param json [String]
        # @param tick_class [Quant::Ticks::Tick]
        # @return [Quant::Ticks::Tick]
        # @example
        #  json = "{\"ct\":\"2024-01-15 03:12:23 UTC\", \"cp\":5.0, \"iv\":\"1d\", \"bv\":0.0, \"tv\":0.0, \"t\":0}"
        #  Quant::Ticks::Serializers::Tick.from_json(json, tick_class: Quant::Ticks::Spot)
        def self.from_json(json, tick_class:)
          hash = Oj.load(json)
          from(hash, tick_class: tick_class)
        end

        # Returns a +Hash+ of the Spot tick's key properties
        #
        # Serialized Keys:
        #
        # - ct: close timestamp
        # - iv: interval
        # - cp: close price
        # - bv: base volume
        # - tv: target volume
        # - t: trades
        #
        # @param tick [Quant::Ticks::Tick]
        # @return [Hash]
        # @example
        #  Quant::Ticks::Serializers::Tick.to_h(tick)
        #  # => { "ct" => "2024-02-13 03:12:23 UTC", "cp" => 5.0, "iv" => "1d", "bv" => 0.0, "tv" => 0.0, "t" => 0 }
        def self.to_h(tick)
          { "ct" => tick.close_timestamp,
            "cp" => tick.close_price,
            "iv" => tick.interval.to_s,
            "bv" => tick.base_volume,
            "tv" => tick.target_volume,
            "t" => tick.trades }
        end

        def self.from(hash, tick_class:)
          tick_class.new(
            close_timestamp: hash["ct"],
            close_price: hash["cp"],
            interval: hash["iv"],
            base_volume: hash["bv"],
            target_volume: hash["tv"],
            trades: hash["t"]
          )
        end
      end
    end
  end
end
