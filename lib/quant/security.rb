# frozen_string_literal: true

require_relative "security_class"

module Quant
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
