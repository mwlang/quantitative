# frozen_string_literal: true

module Quant
  module Ticks
    class Spot < Value
      def self.from(hash)
        new(close_timestamp: hash["ct"], close_price: hash["c"], base_volume: hash["bv"], target_volume: hash["tv"])
      end

      def self.from_json(json)
        from Oj.load(json)
      end

      def initialize(close_timestamp:, close_price:, interval: nil, base_volume: 0.0, target_volume: 0.0, trades: 0)
        super(price: close_price, timestamp: close_timestamp, interval: interval, volume: base_volume, trades: trades)
        @target_volume = target_volume.to_i
      end

      def corresponding?(other)
        close_timestamp == other.close_timestamp
      end

      def to_h
        { "ct" => close_timestamp,
          "c" => close_price,
          "iv" => interval.to_s,
          "bv" => base_volume,
          "tv" => target_volume,
          "t" => trades }
      end
    end
  end
end
