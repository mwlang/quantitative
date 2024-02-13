# frozen_string_literal: true

require_relative "tick"

module Quant
  module Ticks
    class Spot < Tick
      include TimeMethods

      attr_reader :interval, :series
      attr_reader :close_timestamp, :open_timestamp
      attr_reader :open_price, :high_price, :low_price, :close_price
      attr_reader :base_volume, :target_volume, :trades

      def initialize(
        price: nil,
        timestamp: nil,
        close_price: nil,
        close_timestamp: nil,
        volume: nil,
        interval: nil,
        base_volume: nil,
        target_volume: nil,
        trades: nil
      )
        raise ArgumentError, "Must supply a spot price as either :price or :close_price" unless price || close_price

        @close_price = (close_price || price).to_f

        @interval = Interval[interval]

        @close_timestamp = extract_time(timestamp || close_timestamp || Quant.current_time)
        @open_timestamp = @close_timestamp

        @base_volume = (volume || base_volume).to_i
        @target_volume = (target_volume || @base_volume).to_i

        @trades = trades.to_i
        super()
      end

      alias timestamp close_timestamp
      alias price close_price
      alias oc2 close_price
      alias hl2 close_price
      alias hlc3 close_price
      alias ohlc4 close_price
      alias delta close_price
      alias volume base_volume

      def ==(other)
        [close_price, close_timestamp] == [other.close_price, other.close_timestamp]
      end

      def corresponding?(other)
        close_timestamp == other.close_timestamp
      end

      def indicators
        @indicators ||= IndicatorPoints.new(tick: self)
      end

      def inspect
        "#<#{self.class.name} cp=#{close_price.to_f} ct=#{close_timestamp.strftime("%Y-%m-%d")} iv=#{interval.to_s} v=#{volume}>"
      end
    end
  end
end
