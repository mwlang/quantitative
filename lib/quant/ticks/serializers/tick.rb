# frozen_string_literal: true

module Quant
  module Ticks
    module Serializers
      class Tick
        # Returns a +String+ that is a valid CSV row
        # @param tick [Quant::Ticks::Tick]
        # @param headers [Boolean]
        # @return [String]
        # @example
        #  Quant::Ticks::Serializers::Tick.to_csv(tick)
        #  # => "1d,9999,5.0\n"
        # @example
        #  Quant::Ticks::Serializers::Tick.to_csv(tick, headers: true)
        #  # => "iv,ct,cp\n1d,9999,5.0\n"
        def self.to_csv(tick, headers: false)
          hash = to_h(tick)
          row = CSV::Row.new(hash.keys, hash.values)
          return row.to_csv unless headers

          header_row = CSV::Row.new(hash.keys, hash.keys)
          header_row.to_csv << row.to_csv
        end

        # Returns a +String+ that is a valid JSON representation of the tick's key properties.
        # @param tick [Quant::Ticks::Tick]
        # @return [String]
        # @example
        #  Quant::Ticks::Serializers::Tick.to_json(tick)
        #  # => "{\"iv\":\"1d\",\"ct\":9999,\"cp\":5.0}"
        def self.to_json(tick)
          Oj.dump to_h(tick)
        end

        # Returns a Ruby +Hash+ comprised of the tick's key properties.
        # @param tick [Quant::Ticks::Tick]
        # @return [Hash]
        # @example
        #  Quant::Ticks::Serializers::Tick.to_h(tick)
        #  # => { "iv" => "1d", "ct" => 9999, "cp" => 5.0 }
        def self.to_h(instance)
          raise NotImplementedError
        end

        # Returns a +Quant::Ticks::Tick+ from a Ruby +Hash+.
        # @param hash [Hash]
        # @param tick_class [Quant::Ticks::Tick]
        # @return [Quant::Ticks::Tick]
        # @example
        #  hash = { "ct" => 2024-01-15 03:12:23 UTC", "cp" => 5.0, "iv" => "1d", "bv" => 0.0, "tv" => 0.0, "t" => 0}
        #  Quant::Ticks::Serializers::Tick.from(hash, tick_class: Quant::Ticks::Spot)
        def self.from(hash, tick_class:)
          raise NotImplementedError
        end

        # Returns a +Quant::Ticks::Tick+ from a valid JSON +String+.
        # @param json [String]
        # @param tick_class [Quant::Ticks::Tick]
        # @return [Quant::Ticks::Tick]
        # @example
        #  json = "{\"ct\":\"2024-01-15 03:12:23 UTC\", \"cp\":5.0, \"iv\":\"1d\", \"bv\":0.0, \"tv\":0.0, \"t\":0}"
        #  Quant::Ticks::Serializers::Tick.from_json(json, tick_class: Quant::Ticks::Spot)
        def self.from_json(json, tick_class:)
          hash = Oj.load(json)
          from(hash, tick_class: tick_class)
        end
      end
    end
  end
end
