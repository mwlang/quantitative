# frozen_string_literal: true

module Quant
  module Ticks
    # A +Spot+ is a single price point in time.  It is the most basic form of a {Quant::Ticks::Tick} and is usually used to represent
    # a continuously streaming tick that just has a single price point at a given point in time.
    # @example
    #   spot = Quant::Ticks::Spot.new(price: 100.0, timestamp: Time.now)
    #   spot.price # => 100.0
    #   spot.timestamp # => 2018-01-01 12:00:00 UTC
    #
    # @example
    #   spot = Quant::Ticks::Spot.from({ "p" => 100.0, "t" => "2018-01-01 12:00:00 UTC", "bv" => 1000 })
    #   spot.price # => 100.0
    #   spot.timestamp # => 2018-01-01 12:00:00 UTC
    #   spot.volume # => 1000
    class Spot < Tick
      include TimeMethods

      attr_reader :series
      attr_reader :close_timestamp, :open_timestamp
      attr_reader :close_price
      attr_reader :base_volume, :target_volume, :trades

      def initialize(
        price: nil,
        timestamp: nil,
        close_price: nil,
        close_timestamp: nil,
        volume: nil,
        base_volume: nil,
        target_volume: nil,
        trades: nil
      )
        raise ArgumentError, "Must supply a spot price as either :price or :close_price" unless price || close_price

        @close_price = (close_price || price).to_f

        @close_timestamp = extract_time(timestamp || close_timestamp || Quant.current_time)
        @open_timestamp = @close_timestamp

        @base_volume = (volume || base_volume).to_i
        @target_volume = (target_volume || @base_volume).to_i

        @trades = trades.to_i
        super()
      end

      alias timestamp close_timestamp
      alias price close_price
      alias high_price close_price
      alias low_price close_price
      alias open_price close_price
      alias oc2 close_price
      alias hl2 close_price
      alias hlc3 close_price
      alias ohlc4 close_price
      alias delta close_price
      alias volume base_volume

      # Two ticks are equal if they have the same close price and close timestamp.
      def ==(other)
        [close_price, close_timestamp] == [other.close_price, other.close_timestamp]
      end

      # The corresponding? method helps determine that the other tick's timestamp is the same as this tick's timestamp,
      # which is useful when aligning ticks between two separate series where one starts or ends at a different time,
      # or when there may be gaps in the data between the two series.
      def corresponding?(other)
        close_timestamp == other.close_timestamp
      end

      def inspect
        "#<#{self.class.name} ct=#{close_timestamp} c=#{close_price.to_f} v=#{volume}>"
      end
    end
  end
end
