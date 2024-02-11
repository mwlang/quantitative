# frozen_string_literal: true

module Quant
  module Ticks
    # Value ticks are the most basic ticks and are used to represent a single price point (no open, high, low, close, etc.)
    # and a single timestamp.  Usually, these are best used in streaming data where ticks are flowing in every second or whatever
    # interval that's appropriate for the data source.
    # Often indicators and charts still want a universal public interface (i.e. open_price, high_price, volume, etc.), so we add
    # those methods here and inherit and redefine upstream as appropriate.
    #
    # For Value ticks:
    # * The +price+ given is set for all *_price fields.
    # * The +volume+ is set for both base and target volume.
    # * The +timestamp+ is set for both open and close timestamps.
    class Value
      include TimeMethods

      attr_reader :interval, :series
      attr_reader :close_timestamp, :open_timestamp
      attr_reader :open_price, :high_price, :low_price, :close_price
      attr_reader :base_volume, :target_volume, :trades
      attr_reader :green, :doji

      def initialize(price:, timestamp: Quant.current_time, interval: nil, volume: 0, trades: 0)
        @interval = Interval[interval]

        @close_timestamp = extract_time(timestamp)
        @open_timestamp = @close_timestamp

        @close_price = price.to_f
        @open_price = close_price
        @high_price = close_price
        @low_price = close_price

        @base_volume = volume.to_i
        @target_volume = volume.to_i
        @trades = trades.to_i

        # Set the series by appending to the series
        @series = nil
      end

      alias oc2 close_price
      alias hl2 close_price
      alias hlc3 close_price
      alias ohlc4 close_price
      alias delta close_price
      alias volume base_volume

      def corresponding?(other)
        close_timestamp == other.close_timestamp
      end

      def ==(other)
        to_h == other.to_h
      end

      # ticks are immutable across series so we can easily initialize sub-sets or new series
      # with the same ticks while allowing each series to have its own state and full
      # control over the ticks within its series
      def assign_series(new_series)
        assign_series!(new_series) if @series.nil?

        # dup.tap do |new_tick|
        #   # new_tick.instance_variable_set(:@series, new_series)
        #   new_tick.instance_variable_set(:@indicators, indicators)
        # end
      end

      def assign_series!(new_series)
        @series = new_series
        self
      end

      def inspect
        "#<#{self.class.name} iv=#{interval} ct=#{close_timestamp.strftime("%Y-%m-%d")} o=#{open_price} c=#{close_price} v=#{volume}>"
      end

      def to_h
        Quant::Ticks::Serializers::Value.to_h(self)
      end

      def to_json(*_args)
        Quant::Ticks::Serializers::Value.to_json(self)
      end
    end
  end
end
