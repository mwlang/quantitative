# frozen_string_literal: true

module Quant
  module Attributes
    # Tracks all defined attributes, allowing child classes to inherit their parent's attributes.
    # The registry key is the class registering an attrbritute and is itself a hash of the attribute name
    # and the attribute's key and default value.
    # Internal use only.
    #
    # @example
    #   { Quant::Indicators::IndicatorPoint => {
    #       tick: { key: nil, default: nil },
    #       source: { key: "src", default: nil },
    #       input: { key: "in", default: nil }
    #     },
    #     Quant::Indicators::PingPoint => {
    #       pong: { key: nil, default: nil },
    #       compute_count: { key: nil, default: 0 }
    #     }
    #   }
    # @return [Hash] The registry of all defined attributes.
    def self.registry
      @registry ||= {}
    end

    # Removes the given class from the registry. Useful for testing.
    def self.deregister(klass)
      registry.delete(klass)
    end

    # Registers an attribute for a class in the registry.
    # Internal use only.
    #
    # @param klass [Class] The class registering the attribute
    # @param name [Symbol] The name of the attribute
    # @param key [String] The key to use when serializing the attribute
    # @param default [Object] The default value for the attribute
    def self.register(klass, name, key, default)
      # Disallow redefining or replacing a key as it is easy to miss the overwrite
      # and leads to serialization surprises.
      if key && registry.values.flat_map(&:values).map{ |entry| entry[:key] }.include?(key)
        raise Errors::DuplicateAttributesKeyError, "Attribute Key #{key} already defined!"
      end

      registry[klass] ||= {}
      registry[klass][name] = { key: key, default: default }
    end

    module InstanceMethods
      def initialize(...)
        initialize_attributes
        super(...)
      end

      # Iterates over all defined attributes in a child => parent hierarchy,
      # and yields the name and entry for each.
      def each_attribute(&block)
        klass = self.class
        loop do
          attributes = Attributes.registry[klass]
          break if attributes.nil?

          attributes.each{ |name, entry| block.call(name, entry) }
          klass = klass.superclass
        end
      end

      # Initializes the defined attributes with default values and
      # defines accessor methods for each attribute.
      # If a child class redefines a parent's attribute, the child's
      # definition will be used.
      def initialize_attributes
        each_attribute do |name, entry|
          # use the child's definition, skipping the parent's
          next if respond_to?(name)

          ivar_name = "@#{name}"
          instance_variable_set(ivar_name, entry[:default])
          define_singleton_method(name) { instance_variable_get(ivar_name) }
          define_singleton_method("#{name}=") { |value| instance_variable_set(ivar_name, value) }
        end
      end

      # Serializes keys that have been defined as serializeable attributes
      # Key values that are nil are removed from the hash
      # @return [Hash] The serialized attributes as a Ruby Hash.
      def to_h
        {}.tap do |key_values|
          each_attribute do |name, entry|
            next unless entry[:key]

            ivar_name = "@#{name}"
            value = instance_variable_get(ivar_name)

            key_values[entry[:key]] = value if value
          end
        end
      end

      # Serializes keys that have been defined as serializeable attributes
      # Key values that are nil are removed from the hash
      # @return [String] The serialized attributes as a JSON string.
      def to_json(*args)
        Oj.dump(to_h, *args)
      end
    end

    module ClassMethods
      # Define an +attribute+ for the class that can optionally be serialized.
      # Works much like an attr_accessor does, but also manages serialization for
      # #to_h and #to_json methods.
      #
      # An +attribute+ will result in a same-named instance on the class when
      # it is instantiated and it will set a default value if one is provided.
      #
      # @param name [Symbol] The name of the attribute and it's accessor methods
      # @param key [String] The key to use when serializing the attribute
      # @param default [Object] The default value for the attribute
      #
      # @examples
      #   attribute :tick                 # will not serialize to a key
      #   attribute :source, key: "src"   # serializes to "src" key
      #   attribute :input, key: "in"     # serializes to "in" key
      def attribute(name, key: nil, default: nil)
        Attributes.register(self, name, key, default)
      end
    end

    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.prepend(InstanceMethods)
    end
  end
end
