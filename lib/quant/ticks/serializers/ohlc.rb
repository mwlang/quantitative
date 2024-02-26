# frozen_string_literal: true

module Quant
  module Ticks
    module Serializers
      class OHLC < Tick
        # Returns a +Quant::Ticks::Tick+ from a valid JSON +String+.
        # @param json [String]
        # @param tick_class [Quant::Ticks::Tick]
        # @return [Quant::Ticks::Tick]
        # @example
        #  json =
        #  Quant::Ticks::Serializers::Tick.from_json(json, tick_class: Quant::Ticks::Spot)
        def self.from_json(json, tick_class:)
          hash = Oj.load(json)
          from(hash, tick_class: tick_class)
        end

        # Instantiates a tick from a +Hash+.  The hash keys are expected to be the same as the serialized keys.
        #
        # Serialized Keys:
        # - ot: open timestamp
        # - ct: close timestamp
        # - o: open price
        # - h: high price
        # - l: low price
        # - c: close price
        # - bv: base volume
        # - tv: target volume
        # - t: trades
        # - g: green
        # - j: doji
        def self.from(hash, tick_class:)
          tick_class.new \
            open_timestamp: hash["ot"],
            close_timestamp: hash["ct"],

            open_price: hash["o"],
            high_price: hash["h"],
            low_price: hash["l"],
            close_price: hash["c"],

            base_volume: hash["bv"],
            target_volume: hash["tv"],

            trades: hash["t"],
            green: hash["g"],
            doji: hash["j"]
        end

        # Returns a +Hash+ of the Spot tick's key properties
        #
        # Serialized Keys:
        #
        # - ot: open timestamp
        # - ct: close timestamp
        # - o: open price
        # - h: high price
        # - l: low price
        # - c: close price
        # - bv: base volume
        # - tv: target volume
        # - t: trades
        # - g: green
        # - j: doji
        #
        # @param tick [Quant::Ticks::Tick]
        # @return [Hash]
        # @example
        #  Quant::Ticks::Serializers::Tick.to_h(tick)
        #  # => { "ot" => [Time], "ct" => [Time], "o" => 1.0, "h" => 2.0,
        #  #      "l" => 0.5, "c" => 1.5, "bv" => 6.0, "tv" => 5.0, "t" => 1, "g" => true, "j" => true }
        def self.to_h(tick)
          { "ot" => tick.open_timestamp,
            "ct" => tick.close_timestamp,

            "o" => tick.open_price,
            "h" => tick.high_price,
            "l" => tick.low_price,
            "c" => tick.close_price,

            "bv" => tick.base_volume,
            "tv" => tick.target_volume,

            "t" => tick.trades,
            "g" => tick.green,
            "j" => tick.doji }
        end
      end
    end
  end
end
