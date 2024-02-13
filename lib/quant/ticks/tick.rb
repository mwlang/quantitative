# frozen_string_literal: true

module Quant
  module Ticks
    # +Tick+ is the common ancestor for all Ticks and holds the logic for inteacting with series and indicators.
    # The public interface is devoid of properties around price, volume, and timestamp, etc.  Descendant classes
    # are responsible for defining the properties and how they are represented.
    #
    # The +Tick+ class is designed to be immutable and is intended to be used as a value object.  This means that
    # once a +Tick+ is created, it cannot be changed.  This is important for the integrity of the series and
    # indicators that depend on the ticks within the series.
    #
    # When a tick is added to a series, it is locked into the series and ownership cannot be changed.  This is important
    # for the integrity of the series and indicators that depend on the ticks within the series.  This is a key design
    # to being able to being able to not only compute indicators on the ticks just once, but also avoid recomputing
    # indicators when series are limited/sliced/filtered into subsets of the original series.
    class Tick
      def self.from(hash)
        default_serializer_class.from(hash, tick_class: self)
      end

      def self.from_json(json)
        default_serializer_class.from_json(json, tick_class: self)
      end

      attr_reader :series

      def initialize
        # Set the series by appending to the series
        @series = nil
      end

      # ticks always belong to the first series they're assigned so we can easily spin off
      # sub-sets or new series with the same ticks while allowing each series to have
      # its own state and full control over the ticks within its series
      def assign_series(new_series)
        assign_series!(new_series) if @series.nil?
        self
      end

      def assign_series!(new_series)
        @series = new_series
        @interval = new_series.interval if @interval.nil?
        self
      end

      def to_h(serializer_class: default_serializer_class)
        serializer_class.to_h(self)
      end

      def to_json(serializer_class: default_serializer_class)
        serializer_class.to_json(self)
      end

      def to_csv(serializer_class: default_serializer_class, headers: false)
        serializer_class.to_csv(self, headers: headers)
      end

      # Reflects the serializer class from the tick class' name.
      # @note internal use only.
      def self.default_serializer_class
        Object.const_get "Quant::Ticks::Serializers::#{name.split("::").last}"
      end

      # Reflects the serializer class from the tick class' name.
      # @note internal use only.
      def default_serializer_class
        self.class.default_serializer_class
      end
    end
  end
end
