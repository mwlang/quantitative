# frozen_string_literal: true

require_relative "asset_class"

module Quant
  # A {Quant::Asset} is a representation of a financial instrument such as a stock, option, future, or currency.
  # It is used to represent the instrument that is being traded, analyzed, or managed.
  #
  # Not all data sources have a rich set of attributes for their assets or securities.  The {Quant::Asset} is designed
  # to be flexible and to support a wide variety of data sources and use-cases.  The most common use-cases are supported
  # while allowing for additional attributes to be added via the +meta+ attribute, which is tyipically just a Hash,
  # but can be any object that can hold useful information about the asset such as currency formatting, precision, etc.
  # @example
  #   asset = Quant::Asset.new(symbol: "AAPL", name: "Apple Inc.", asset_class: :stock, exchange: "NASDAQ")
  #   asset.symbol # => "AAPL"
  #   asset.name # => "Apple Inc."
  #   asset.stock? # => true
  #   asset.option? # => false
  #   asset.future? # => false
  #   asset.currency? # => false
  #   asset.exchange # => "NASDAQ"
  #
  #   # Can serialize two ways:
  #   asset.to_h # => { "s" => "AAPL" }
  #   asset.to_h(full: true) # => { "s" => "AAPL", "n" => "Apple Inc.", "sc" => "stock", "x" => "NASDAQ" }
  class Asset
    attr_reader :symbol, :name, :asset_class, :id, :exchange, :source, :meta, :created_at, :updated_at

    def initialize(
      symbol:,
      name: nil,
      id: nil,
      active: true,
      tradeable: true,
      exchange: nil,
      source: nil,
      asset_class: nil,
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
      @asset_class = AssetClass.new(asset_class)
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

    AssetClass::CLASSES.each do |class_name|
      define_method("#{class_name}?") do
        asset_class == class_name
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
        "sc" => asset_class.to_s,
        "src" => source.to_s }
    end

    def to_json(*args, full: false)
      Oj.dump(to_h(full: full), *args)
    end
  end
end
