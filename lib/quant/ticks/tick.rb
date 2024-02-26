# frozen_string_literal: true

module Quant
  module Ticks
    # {Quant::Ticks::Tick} is the abstract ancestor for all Ticks and holds
    # the logic for interacting with series and indicators. The public
    # interface is devoid of properties around price, volume, and timestamp, etc.
    # Descendant classes are responsible for defining the properties and
    # how they are represented.

    # The {Quant::Ticks::Tick} class is designed to be immutable and is
    # intended to be used as a value object.  This means that once a
    # {Quant::Ticks::Tick} is created, it cannot be changed.  This is important
    # for the integrity of the series and indicators that depend on the
    # ticks within the series.

    # When a tick is added to a series, it is locked into the series and
    # ownership cannot be changed.  This is important for the integrity
    # of the series and indicators that depend on the ticks within the series.
    # This is a key design to being able to being able to not only compute
    # indicators on the ticks just once, but also avoid recomputing indicators
    # when series are limited/sliced/filtered into subsets of the original series.

    # Ticks can be serialized to and from Ruby Hash, JSON strings, and CSV strings.
    class Tick
      # Returns a {Quant::Ticks::Tick} from a Ruby +Hash+.  The default
      # serializer is used to generate the {Quant::Ticks::Tick}.
      # @param hash [Hash]
      # @param serializer_class [Class] The serializer class to use for the conversion.
      # @return [Quant::Ticks::Tick]
      # @example
      #   hash = { "timestamp" => "2018-01-01 12:00:00 UTC", "price" => 100.0, "volume" => 1000 }
      #   Quant::Ticks::Tick.from(hash)
      #   # => #<Quant::Ticks::Spot:0x00007f9e3b8b3e08 @timestamp=2018-01-01 12:00:00 UTC, @price=100.0, @volume=1000>
      def self.from(hash, serializer_class: nil)
        serializer_class ||= default_serializer_class
        serializer_class.from(hash, tick_class: self)
      end

      # Returns a {Quant::Ticks::Tick} from a JSON string.  The default
      # serializer is used to generate the {Quant::Ticks::Tick}.
      # @param json [String]
      # @param serializer_class [Class] The serializer class to use for the conversion.
      # @return [Quant::Ticks::Tick]
      # @example
      #   json = "{\"timestamp\":\"2018-01-01 12:00:00 UTC\",\"price\":100.0,\"volume\":1000}"
      #   Quant::Ticks::Tick.from_json(json)
      #   # => #<Quant::Ticks::Spot:0x00007f9e3b8b3e08 @timestamp=2018-01-01 12:00:00 UTC, @price=100.0, @volume=1000>
      def self.from_json(json, serializer_class: default_serializer_class)
        serializer_class.from_json(json, tick_class: self)
      end

      attr_reader :series, :indicators

      def initialize
        # Set the series by appending to the series or calling #assign_series method
        @series = nil
        @interval = nil
        @indicators = {}
      end

      def interval
        @series&.interval || Interval[nil]
      end

      # Ticks always belong to the first series they're assigned so we can easily spin off
      # sub-sets or new series with the same ticks while allowing each series to have
      # its own state and full control over the ticks within its series
      def assign_series(new_series)
        assign_series!(new_series) unless series?
        self
      end

      # Returns true if the tick is assigned to a series.  The first series a tick is assigned
      # to is the series against which the indicators compute.
      def series?
        !!@series
      end

      # Ticks always belong to the first series they're assigned so we can easily spin off
      # sub-sets or new series with the same ticks.  However, if you need to reassign the
      # series, you can use this method to force the change of series ownership.
      #
      # The series interval is also assigned to the tick if it is not already set.
      def assign_series!(new_series)
        @series = new_series
        @interval ||= new_series.interval
        self
      end

      # Returns a Ruby hash for the Tick.  The default serializer is used
      # to generate the hash.
      #
      # @param serializer_class [Class] the serializer class to use for the conversion.
      # @example
      #   tick.to_h
      #   # => { timestamp: "2018-01-01 12:00:00 UTC", price: 100.0, volume: 1000 }
      def to_h(serializer_class: default_serializer_class)
        serializer_class.to_h(self)
      end

      # Returns a JSON string for the Tick.  The default serializer is used
      # to generate the JSON string.
      #
      # @param serializer_class [Class] the serializer class to use for the conversion.
      # @example
      #   tick.to_json
      #   # => "{\"timestamp\":\"2018-01-01 12:00:00 UTC\",\"price\":100.0,\"volume\":1000}"
      def to_json(serializer_class: default_serializer_class)
        serializer_class.to_json(self)
      end

      # Returns a CSV row as a String for the Tick.  The default serializer
      # is used to generate the CSV string.  If headers is true, two lines
      # returned separated by newline.
      # The first line is the header row and the second line is the data row.
      #
      # @param serializer_class [Class] the serializer class to use for the conversion.
      # @example
      #   tick.to_csv(headers: true)
      #   # => "timestamp,price,volume\n2018-01-01 12:00:00 UTC,100.0,1000\n"
      def to_csv(serializer_class: default_serializer_class, headers: false)
        serializer_class.to_csv(self, headers: headers)
      end

      # Reflects the serializer class from the tick's class name.
      # @note internal use only.
      def self.default_serializer_class
        Object.const_get "Quant::Ticks::Serializers::#{name.split("::").last}"
      end

      # Reflects the serializer class from the tick's class name.
      # @note internal use only.
      def default_serializer_class
        self.class.default_serializer_class
      end
    end
  end
end
