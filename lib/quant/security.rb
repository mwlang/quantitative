# frozen_string_literal: true

require_relative "security_class"

module Quant
  # A +Security+ is a representation of a financial instrument such as a stock, option, future, or currency.
  # It is used to represent the instrument that is being traded, analyzed, or managed.
  # @example
  #   security = Quant::Security.new(symbol: "AAPL", name: "Apple Inc.", security_class: :stock, exchange: "NASDAQ")
  #   security.symbol # => "AAPL"
  #   security.name # => "Apple Inc."
  #   security.stock? # => true
  #   security.option? # => false
  #   security.future? # => false
  #   security.currency? # => false
  #   security.exchange # => "NASDAQ"
  #   security.to_h # => { "s" => "AAPL", "n" => "Apple Inc.", "sc" => "stock", "x" => "NASDAQ" }
  class Security
    attr_reader :symbol, :name, :security_class, :id, :exchange, :source, :meta, :created_at, :updated_at

    def initialize(
      symbol:,
      name: nil,
      id: nil,
      active: true,
      tradeable: true,
      exchange: nil,
      source: nil,
      security_class: nil,
      created_at: Quant.current_time,
      updated_at: Quant.current_time,
      meta: {}
    )
      raise ArgumentError, "symbol is required" unless symbol

      @symbol = symbol.to_s.upcase
      @name = name
      @id = id
      @tradeable = tradeable
      @active = active
      @exchange = exchange
      @source = source
      @security_class = SecurityClass.new(security_class)
      @created_at = created_at
      @updated_at = updated_at
      @meta = meta
    end

    def active?
      !!@active
    end

    def tradeable?
      !!@tradeable
    end

    SecurityClass::CLASSES.each do |class_name|
      define_method("#{class_name}?") do
        security_class == class_name
      end
    end

    def to_h(full: false)
      return { "s" => symbol } unless full

      { "s" => symbol,
        "n" => name,
        "id" => id,
        "t" => tradeable?,
        "a" => active?,
        "x" => exchange,
        "sc" => security_class.to_s,
        "src" => source.to_s }
    end

    def to_json(*args, full: false)
      Oj.dump(to_h(full: full), *args)
    end
  end
end
