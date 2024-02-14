# frozen_string_literal: true

module Quant
  # Ticks belong to the first series they're associated with always.
  # There are no provisions for series merging their ticks to one series!
  # Indicators will be computed against the parent series of a list of ticks, so we
  # can safely work with subsets of a series and indicators will compute just once.
  class Series
    include Enumerable
    extend Forwardable

    def self.from_file(filename:, symbol:, interval:, folder: nil)
      symbol = symbol.to_s.upcase
      interval = Interval[interval]

      filename = Rails.root.join("historical", folder, "#{symbol.upcase}.txt") if filename.nil?
      raise "File #{filename} does not exist" unless File.exist?(filename)

      lines = File.read(filename).split("\n")
      ticks = lines.map{ |line| Quant::Ticks::OHLC.from_json(line) }

      from_ticks(symbol: symbol, interval: interval, ticks: ticks)
    end

    def self.from_json(symbol:, interval:, json:)
      from_hash symbol: symbol, interval: interval, hash: Oj.load(json)
    end

    def self.from_hash(symbol:, interval:, hash:)
      ticks = hash.map { |tick_hash| Quant::Ticks::OHLC.from(tick_hash) }
      from_ticks(symbol: symbol, interval: interval, ticks: ticks)
    end

    def self.from_ticks(symbol:, interval:, ticks:)
      ticks = ticks.sort_by(&:close_timestamp)

      new(symbol: symbol, interval: interval).tap do |series|
        ticks.each { |tick| series << tick }
      end
    end

    attr_reader :symbol, :interval, :ticks

    def initialize(symbol:, interval:)
      @symbol = symbol
      @interval = interval
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
    def_delegator :@ticks, :select
    def_delegator :@ticks, :select!
    def_delegator :@ticks, :reject
    def_delegator :@ticks, :reject!
    def_delegator :@ticks, :first
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
      @ticks << tick.assign_series(self)
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
