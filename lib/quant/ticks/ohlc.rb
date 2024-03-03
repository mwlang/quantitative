# frozen_string_literal: true

require_relative "tick"

module Quant
  module Ticks
    # A {Quant::Ticks::OHLC} is a bar or candle for a point in time that
    # has an open, high, low, and close price. It is the most common form
    # of a {Quant::Ticks::Tick} and is usually used to representa time
    # period such as a minute, hour, day, week, or month.
    #
    # The {Quant::Ticks::OHLC} is used to represent the price action of
    # an asset The interval of the {Quant::Ticks::OHLC} is the time period
    # that the {Quant::Ticks::OHLC} represents, such has hourly, daily,
    # weekly, etc.
    class OHLC < Tick
      include TimeMethods

      attr_reader :series
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

      # The corresponding? method helps determine that the other tick's timestamp is the same as this tick's timestamp,
      # which is useful when aligning ticks between two separate series where one starts or ends at a different time,
      # or when there may be gaps in the data between the two series.
      def corresponding?(other)
        [open_timestamp, close_timestamp] == [other.open_timestamp, other.close_timestamp]
      end

      # Two OHLC ticks are equal if their interval, close_timestamp, and close_price are equal.
      def ==(other)
        [interval, close_timestamp, close_price] == [other.interval, other.close_timestamp, other.close_price]
      end

      # Returns the percent daily price change from open_price to close_price, ranging from 0.0 to 1.0.
      # A positive value means the price increased, and a negative value means the price decreased.
      # A value of 0.0 means no change.
      # @return [Float]
      def daily_price_change
        return open_price.zero? ? 0.0 : -1.0 if close_price.zero?
        return 0.0 if open_price == close_price

        (open_price / close_price) - 1.0
      end

      # Calculates the absolute change from the open_price to the close_price, divided by the average of the
      # open_price and close_price. This method will give a value between 0 and 2, where 0 means no change,
      # 1 means the price doubled, and 2 means the price went to zero.
      # This method is useful for comparing the volatility of different assets.
      # @return [Float]
      def daily_price_change_ratio
        (open_price - close_price).abs / oc2
      end

      # Set the #green? property to true when the close_price is greater than or equal to the open_price.
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

      # Computes a doji candlestick pattern.  A doji is a candlestick pattern that occurs when the open and close
      # are the same or very close to the same.  The high and low are also very close to the same.  The doji pattern
      # is a sign of indecision in the market. It is a sign that the market is not sure which way to go.
      # @return [Boolean]
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

      def inspect
        "#<#{self.class.name} ct=#{close_timestamp.iso8601} o=#{open_price} h=#{high_price} l=#{low_price} c=#{close_price} v=#{volume}>"
      end
    end
  end
end
