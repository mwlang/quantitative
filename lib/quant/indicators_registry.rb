# frozen_string_literal: true

module Quant
  module IndicatorsRegistry
    def self.included(base)
      base.extend(ClassMethods)
    end

    def define_indicator_accessors(indicator_source:)
      self.class.define_indicator_accessors(indicator_source:)
    end

    module ClassMethods
      def registry
        @registry ||= {}
      end

      class RegistryEntry
        attr_reader :name, :indicator_class

        def initialize(name:, indicator_class:)
          @name = name
          @indicator_class = indicator_class
        end

        def key
          "#{indicator_class.name}::#{name}"
        end

        def standard?
          !pivot? && !dominant_cycle?
        end

        def pivot?
          indicator_class < Indicators::Pivots::Pivot
        end

        def dominant_cycle?
          indicator_class < Indicators::DominantCycles::DominantCycle
        end
      end

      def register(name:, indicator_class:)
        entry = RegistryEntry.new(name:, indicator_class:)
        registry[entry.key] = entry
        # registry[name] = indicator_class
      end

      def registry_entries_for(indicator_source:)
        return registry.values.select(&:pivot?) if indicator_source.is_a?(PivotsSource)
        return registry.values.select(&:dominant_cycle?) if indicator_source.is_a?(DominantCyclesSource)

        registry.values.select(&:standard?)
      end

      def define_indicator_accessors(indicator_source:)
        registry_entries_for(indicator_source:).each do |entry|
          indicator_source.define_singleton_method(entry.name) { indicator(entry.indicator_class) }
        end
      end
    end
  end
end