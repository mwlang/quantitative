# frozen_string_literal: true

module Quant
  # Ticks belong to the first series they're associated with always.
  # There are no provisions for series merging their ticks to one series!
  # {Indicators} will be computed against the parent series of a list of ticks, so we
  # can safely work with subsets of a series and indicators will compute just once.
  class Series
    include Enumerable
    extend Forwardable

    # Loads a series of ticks when each line is a parsible JSON string that represents a tick.
    # A {Quant::Ticks::TickSerializer} may be passed to convert the parsed JSON to {Quant::Ticks::Tick} object.
    # @param filename [String] The filename to load the ticks from.
    # @param symbol [String] The symbol of the series.
    # @param interval [String] The interval of the series.
    # @param serializer_class [Class] {Quant::Ticks::TickSerializer} class to use for the conversion.
    def self.from_file(filename:, symbol:, interval:, serializer_class: nil)
      raise "File #{filename} does not exist" unless File.exist?(filename)

      ticks = File.read(filename).split("\n").map{ |line| Oj.load(line) }
      from_hash symbol: symbol, interval: interval, hash: ticks, serializer_class: serializer_class
    end

    # Loads a series of ticks when the JSON string represents an array of ticks.
    # A {Quant::Ticks::TickSerializer} may be passed to convert the parsed JSON to {Quant::Ticks::Tick} object.
    # @param symbol [String] The symbol of the series.
    # @param interval [String] The interval of the series.
    # @param json [String] The JSON string to parse into ticks.
    # @param serializer_class [Class] {Quant::Ticks::TickSerializer} class to use for the conversion.
    def self.from_json(symbol:, interval:, json:, serializer_class: nil)
      ticks = Oj.load(json)
      from_hash symbol: symbol, interval: interval, hash: ticks, serializer_class: serializer_class
    end

    # Loads a series of ticks where the hash must be cast to an array of {Quant::Ticks::Tick} objects.
    # @param symbol [String] The symbol of the series.
    # @param interval [String] The interval of the series.
    # @param hash [Array<Hash>] The array of hashes to convert to {Quant::Ticks::Tick} objects.
    # @param serializer_class [Class] {Quant::Ticks::TickSerializer} class to use for the conversion.
    def self.from_hash(symbol:, interval:, hash:, serializer_class: nil)
      ticks = hash.map { |tick_hash| Quant::Ticks::OHLC.from(tick_hash, serializer_class: serializer_class) }
      from_ticks symbol: symbol, interval: interval, ticks: ticks
    end

    # Loads a series of ticks where the array represents an array of {Quant::Ticks::Tick} objects.
    def self.from_ticks(symbol:, interval:, ticks:)
      ticks = ticks.sort_by(&:close_timestamp)

      new(symbol: symbol, interval: interval).tap do |series|
        ticks.each { |tick| series << tick }
      end
    end

    attr_reader :symbol, :interval, :ticks

    def initialize(symbol:, interval:)
      @symbol = symbol
      @interval = Interval[interval]
      @ticks = []
    end

    def limit_iterations(start_iteration, stop_iteration)
      selected_ticks = ticks[start_iteration..stop_iteration]
      return self if selected_ticks.size == ticks.size

      self.class.from_ticks(symbol: symbol, interval: interval, ticks: selected_ticks)
    end

    def limit(period)
      selected_ticks = ticks.select{ |tick| period.cover?(tick.close_timestamp) }
      return self if selected_ticks.size == ticks.size

      self.class.from_ticks(symbol: symbol, interval: interval, ticks: selected_ticks)
    end

    def_delegator :@ticks, :[]
    def_delegator :@ticks, :size
    def_delegator :@ticks, :each
    def_delegator :@ticks, :select!
    def_delegator :@ticks, :reject!
    def_delegator :@ticks, :last

    def highest
      ticks.max_by(&:high_price)
    end

    def lowest
      ticks.min_by(&:low_price)
    end

    def ==(other)
      [symbol, interval, ticks] == [other.symbol, other.interval, other.ticks]
    end

    def dup
      self.class.from_ticks(symbol: symbol, interval: interval, ticks: ticks)
    end

    def inspect
      "#<#{self.class.name} symbol=#{symbol} interval=#{interval} ticks=#{ticks.size}>"
    end

    def <<(tick)
      tick = Ticks::Spot.new(price: tick) if tick.is_a?(Numeric)
      indicators << tick unless tick.series?
      @ticks << tick.assign_series(self)
      self
    end

    def indicators
      @indicators ||= IndicatorsSources.new(series: self)
    end

    def to_h
      { "symbol" => symbol,
        "interval" => interval,
        "ticks" => ticks.map(&:to_h) }
    end

    def to_json(*args)
      Oj.dump(to_h, *args)
    end
  end
end
