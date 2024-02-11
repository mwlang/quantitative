require_relative 'value'

module Quant
  module Ticks
    # serialized keys
    # ot: open timestamp
    # ct: close timestamp
    # iv: interval

    # o: open price
    # h: high price
    # l: low price
    # c: close price

    # bv: base volume
    # tv: target volume
    # ct: close timestamp

    # t: trades
    # g: green
    # j: doji
    class OHLC < Value
      def self.from(hash)
        new \
          open_timestamp: hash["ot"],
          close_timestamp: hash["ct"],
          interval: hash["iv"],

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

      def self.from_json(json)
        from Oj.load(json)
      end

      def initialize(open_timestamp:,
                     close_timestamp:,
                     interval: nil,

                     open_price:,
                     high_price:,
                     low_price:,
                     close_price:,

                     base_volume: 0.0,
                     target_volume: 0.0,

                     trades: 0,
                     green: false,
                     doji: nil)

        super(price: close_price, timestamp: close_timestamp, interval:, trades:)
        @open_timestamp = extract_time(open_timestamp)
        @open_price = open_price.to_f
        @high_price = high_price.to_f
        @low_price = low_price.to_f

        @base_volume = base_volume.to_i
        @target_volume = target_volume.to_i

        @green = green.nil? ? compute_green : green
        @doji = doji.nil? ? compute_doji : doji
      end

      def hl2; ((high_price + low_price) / 2.0) end
      def oc2; ((open_price + close_price) / 2.0) end
      def hlc3; ((high_price + low_price + close_price) / 3.0) end
      def ohlc4; ((open_price + high_price + low_price + close_price) / 4.0) end

      def corresponding?(other)
        [open_timestamp, close_timestamp] == [other.open_timestamp, other.close_timestamp]
      end

      # percent change from open to close
      def delta
        ((open_price / close_price) - 1.0) * 100
      end

      def to_h
        { "ot" => open_timestamp,
          "ct" => close_timestamp,
          "iv" => interval.to_s,

          "o" => open_price,
          "h" => high_price,
          "l" => low_price,
          "c" => close_price,

          "bv" => base_volume,
          "tv" => target_volume,

          "t" => trades,
          "g" => green,
          "j" => doji }
      end

      def as_price(value)
        series.nil? ? value : series.as_price(value)
      end

      def to_s
        ots = interval.daily? ? open_timestamp.strftime('%Y-%m-%d') : open_timestamp.strftime('%Y-%m-%d %H:%M:%S')
        cts = interval.daily? ? close_timestamp.strftime('%Y-%m-%d') : close_timestamp.strftime('%Y-%m-%d %H:%M:%S')
        "#{ots}: o: #{as_price(open_price)}, h: #{as_price(high_price)}, l: #{as_price(low_price)}, c: #{as_price(close_price)} :#{cts}"
      end

      def compute_green
        close_price >= open_price
      end

      def green?
        close_price > open_price
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
