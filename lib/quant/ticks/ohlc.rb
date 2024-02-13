# frozen_string_literal: true

require_relative "tick"

module Quant
  module Ticks
    class OHLC < Tick
      include TimeMethods

      attr_reader :interval, :series
      attr_reader :close_timestamp, :open_timestamp
      attr_reader :open_price, :high_price, :low_price, :close_price
      attr_reader :base_volume, :target_volume, :trades
      attr_reader :green, :doji

      def initialize(
        open_timestamp:,
        close_timestamp:,

        open_price:,
        high_price:,
        low_price:,
        close_price:,

        interval: nil,

        volume: nil,
        base_volume: nil,
        target_volume: nil,

        trades: nil,
        green: nil,
        doji: nil
      )
        @open_timestamp = extract_time(open_timestamp)
        @close_timestamp = extract_time(close_timestamp)

        @open_price = open_price.to_f
        @high_price = high_price.to_f
        @low_price = low_price.to_f
        @close_price = close_price.to_f

        @interval = Interval[interval]

        @base_volume = (volume || base_volume).to_i
        @target_volume = (target_volume || @base_volume).to_i
        @trades = trades.to_i

        @green = green.nil? ? compute_green : green
        @doji = doji.nil? ? compute_doji : doji
        super()
      end

      alias price close_price
      alias timestamp close_timestamp
      alias volume base_volume

      def hl2; ((high_price + low_price) / 2.0) end
      def oc2; ((open_price + close_price) / 2.0) end
      def hlc3; ((high_price + low_price + close_price) / 3.0) end
      def ohlc4; ((open_price + high_price + low_price + close_price) / 4.0) end

      def corresponding?(other)
        [open_timestamp, close_timestamp] == [other.open_timestamp, other.close_timestamp]
      end

      # percent change from open to close
      def price_change
        ((open_price / close_price) - 1.0) * 100
      end

      def compute_green
        close_price >= open_price
      end

      def green?
        @green
      end

      def red?
        !green?
      end

      def doji?
        @doji
      end

      def price_change
        @price_change ||= ((open_price - close_price) / oc2).abs
      end

      def compute_doji
        body_bottom, body_top = [open_price, close_price].sort

        body_length = body_top - body_bottom
        head_length = high_price - [open_price, close_price].max
        tail_length = [open_price, close_price].max - low_price

        body_ratio = 100.0 * (1 - (body_bottom / body_top))
        head_ratio = head_length / body_length
        tail_ratio = tail_length / body_length

        body_ratio < 0.025 && head_ratio > 1.0 && tail_ratio > 1.0
      end
    end
  end
end
