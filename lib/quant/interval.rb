# frozen_string_literal: true

# rubocop:disable Layout/HashAlignment

# Quantitative is a statistical and quantitative library for Ruby 3.x.  It provides a number of classes and modules for working with
# time-series data, financial data, and other quantitative data.  It is designed to be fast, efficient, and easy to use.
#
# == Installation
#
# Add this line to your application's Gemfile:
#
#   gem 'quantitative'
#
# And then execute:
#
#   $ bundle install
#
# Or install it yourself as:
#
#   $ gem install quantitative
#
# == Usage
#
# Quantitative provides a number of classes and modules for working with time-series data, financial data, and other quantitative data.
# It is designed to be fast, efficient, and easy to use.
#
# Here's a simple example of how to use Quantitative:
#
#   require "quantitative"
#
#   # Create a new series
#   series = Quant::Series.new
#
#   # Add some data to the series
#   ticks = [25.0, 26.0, 23.5, 24.5, 25.5, 26.5, 27.5, 28.5, 29.5, 30.5]
#   ticks.each { |tick| series << tick }
#
#   # Print the series
#   pp series
#
module Quant
  # +Quant::Interval+ abstracts away the concept of ticks (candles, bars, etc.) and their duration and offers some basic utilities for
  # working with multiple timeframes.  Intervals are used in +Tick+ and +Series+ classes to define the duration of the ticks.
  #
  # When the +Interval+ is unknown, it is set to +'na'+ (not available) and the duration is set to 0.  The shorthand for this is
  # +Interval.na+. and +Interval[:na]+. and +Interval[nil]+.
  #
  # +Interval+ are instantiated in multple ways to support a wide variety of use-cases.  Here's an example:
  #   Quant::Interval.new("1d")               # => #<Quant::Interval @interval="1d"> (daily interval)
  #   Quant::Interval.new(:daily)             # => #<Quant::Interval @interval="1d">
  #   Quant::Interval[:daily]                 # => #<Quant::Interval @interval="1d">
  #   Quant::Interval.from_resolution(60)     # => #<Quant::Interval @interval="1h">
  #   Quant::Interval.from_resolution("1D")   # => #<Quant::Interval @interval="1d">
  #   Quant::Interval.from_resolution("D")    # => #<Quant::Interval @interval="1d">
  #
  # Intervals have a number of useful methods:
  #  interval = Quant::Interval.new("1d")     # => #<Quant::Interval @interval="1d">  (daily interval)
  #  interval.nil?                            # => false
  #  interval.duration                        # => 86400
  #  interval.ticks_per_minute                # => 0.0006944444444444445
  #  interval.half_life                       # => 43200.0
  #  interval.next_interval                   # => #<Quant::Interval @interval="1w"> (weekly interval)
  #
  # When you don't wish to specify an interval or it is unknown, you can use the +na+ interval:
  #   interval = Quant::Interval.na           # => #<Quant::Interval @interval="na">
  #   interval.nil?                           # => true
  #   interval.duration                       # => 0
  #
  class Interval
    MAPPINGS = {
      na:               { interval: "na",   distance: 0 },
      second:           { interval: "1s",   distance: 1 },
      two_seconds:      { interval: "2s",   distance: 2 },
      three_seconds:    { interval: "3s",   distance: 3 },
      five_seconds:     { interval: "5s",   distance: 5 },
      ten_seconds:      { interval: "10s",  distance: 10 },
      fifteen_seconds:  { interval: "15s",  distance: 15 },
      thirty_seconds:   { interval: "30s",  distance: 30 },
      minute:           { interval: "1m",   distance: 60 },
      one_minute:       { interval: "1m",   distance: 60 },
      three_minutes:    { interval: "3m",   distance: 60 * 3 },
      five_minutes:     { interval: "5m",   distance: 60 * 5 },
      fifteen_minutes:  { interval: "15",   distance: 60 * 15 },
      thirty_minutes:   { interval: "30",   distance: 60 * 30 },
      hour:             { interval: "1h",   distance: 60 * 60 },
      two_hours:        { interval: "2h",   distance: 60 * 60 * 2 },
      four_hours:       { interval: "4h",   distance: 60 * 60 * 4 },
      eight_hours:      { interval: "8h",   distance: 60 * 60 * 8 },
      twelve_hours:     { interval: "12h",  distance: 60 * 60 * 12 },
      daily:            { interval: "1d",   distance: 60 * 60 * 24 },
      weekly:           { interval: "1w",   distance: 60 * 60 * 24 * 7 },
      monthly:          { interval: "1M",   distance: 60 * 60 * 24 * 30 },
    }.freeze

    INTERVAL_DISTANCE = MAPPINGS.values.map { |v| [v[:interval], v[:distance]] }.to_h.freeze

    MAPPINGS.each_pair do |name, values|
      define_singleton_method(name) do
        Interval.new(values[:interval])
      end

      define_method("#{name}?") do
        interval == values[:interval]
      end
    end

    RESOLUTIONS = {
      "1"   => :one_minute,
      "3"   => :three_minutes,
      "5"   => :five_minutes,
      "15"  => :fifteen_minutes,
      "30"  => :thirty_minutes,
      "60"  => :hour,
      "240" => :four_hours,
      "D"   => :daily,
      "1D"  => :daily,
    }.freeze

    def self.all_resolutions
      RESOLUTIONS.keys
    end

    # Instantiates an Interval from a resolution.  For example, TradingView uses resolutions
    # like "1", "3", "5", "15", "30", "60", "240", "D", "1D" to represent the duration of a
    # candlestick.  +from_resolution+ translates resolutions to the appropriate +Interval+.
    def self.from_resolution(resolution)
      ensure_valid_resolution!(resolution)

      Interval.new(MAPPINGS[RESOLUTIONS[resolution]][:interval])
    end

    # Instantiates an Interval from a string or symbol.  If the value is already
    # an +Interval+, it is returned as-is.
    def self.[](value)
      return value if value.is_a? Interval

      from_mappings(value) || Interval.new(value)
    end

    # Looks up the given mapping (i.e. :daily) and returns the Interval for that mapping.
    def self.from_mappings(value)
      mapping = MAPPINGS[value&.to_sym]
      return unless mapping

      Interval.new(mapping[:interval])
    end

    attr_reader :interval

    def initialize(interval)
      ensure_valid_interval!(interval)

      @interval = (interval || "na").to_s
    end

    def nil?
      interval == "na"
    end

    def to_s
      interval
    end

    def duration
      INTERVAL_DISTANCE[interval]
    end
    alias seconds duration

    def ==(other)
      interval == other&.interval
    end

    def ticks_per_minute
      60.0 / seconds
    end

    def half_life
      raise "bad interval #{interval}" if duration.nil?

      duration / 2.0
    end

    # Returns the Interval for the next higher timeframe.
    # For example, hourly -> daily -> weekly -> monthly
    def next_interval
      intervals = INTERVAL_DISTANCE.keys
      Interval.new intervals[intervals.index(interval) + 1] || intervals[-1]
    end

    def self.valid_intervals
      INTERVAL_DISTANCE.keys
    end

    # NOTE: if timestamp doesn't cover a full interval, it will be rounded up to 1
    def ticks_to(timestamp)
      ((timestamp - Quant.current_time) / duration).round(2).ceil
    end

    def timestamp_for(ticks:, timestamp: Quant.current_time)
      timestamp + (ticks * duration)
    end

    def self.ensure_valid_resolution!(resolution)
      return if RESOLUTIONS.keys.include? resolution

      raise InvalidResolution, "resolution (#{resolution}) not a valid resolution. Should be one of: (#{RESOLUTIONS.keys.join(", ")})"
    end

    private

    def valid_intervals
      self.class.valid_intervals
    end

    def ensure_valid_interval!(interval)
      return if interval.nil? || valid_intervals.include?(interval.to_s)

      raise InvalidInterval, "interval (#{interval.inspect}) not a valid interval. Should be one of: (#{valid_intervals.join(", ")})"
    end

    def ensure_valid_resolution!(resolution)
      self.class.ensure_valid_resolution!(resolution)
    end
  end
end
# rubocop:enable Layout/HashAlignment
