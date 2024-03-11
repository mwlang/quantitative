# frozen_string_literal: true

module Quant
  # {Quant::Attributes} is similar to an +attr_accessor+ definition.  It provides a simple DSL
  # for defining attributes or properies on an {Quant::Indicators::IndicatorPoint} class.
  #
  # {Quant::Attributes} tracks all defined attributes from child to parent classes,
  # allowing child classes to inherit their parent's attributes as well as redefine them.
  #
  # The exception on redefining is that a serialized key cannot be redefined.  Experience
  # has proven that this leads to serialization surprises where what was written to a specific
  # key is not what was expected!
  #
  # NOTE: The above design constraint could be improved with a force or overwrite option.
  #
  # If :default is an immediate value (Integer, Float, Boolean, etc.), it will be used as the
  # initial value for the attribute.  If :default is a Symbol, it will send a message on
  # current instance of the class get the default value.
  #
  # @example
  #   class FooPoint < IndicatorPoint
  #     # will not serialize to a key
  #     attribute :bar
  #     # serializes to "bzz" key
  #     attribute :baz, key: "bzz"
  #     # calls the random method on the instance for the default value
  #     attribute :foobar, default: :random
  #     # delegated to the tick's high_price method
  #     attribute :high, default: :high_price
  #     # calls the lambda bound to instance for default
  #     attribute :low, default: -> { high_price - 5 }
  #
  #     def random
  #       rand(100)
  #     end
  #   end
  #
  #   class BarPoint < FooPoint
  #     attribute :bar, key: "brr"                 # redefines and sets the key for bar
  #     attribute :qux, key: "qxx", default: 5.0   # serializes to "qxx" and defaults to 5.0
  #   end
  #
  #   FooPoint.attributes
  #   # => { bar: { key: nil, default: nil },
  #          baz: { key: "bzz", default: nil } }
  #
  #   BarPoint.attributes
  #   # => { bar: { key: "brr", default: nil },
  #   #      baz: { key: "bzz", default: nil },
  #   #      qux: { key: "qxx", default: nil } }
  #
  #   BarPoint.new.bar # => nil
  #   BarPoint.new.qux # => 5.0
  #   BarPoint.new.bar = 2.0 => 2.0
  module Attributes
    # The +registry+ key is the class registering an attrbritute and is itself
    # a hash of the attribute name and the attribute's key and default value.
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
      registry[klass][name] = { key:, default: }
    end

    module InstanceMethods
      # Makes some assumptions about the class's initialization having a +tick+ keyword argument.
      # If one does exist, the +tick+ is considered as a potential source for the declared defaults
      def initialize(...)
        super(...)
        initialize_attributes
      end

      # Returns an array of all classes in the hierarchy, starting with the current class
      def self_and_ancestors
        [this_class = self.class].tap do |classes|
          classes << this_class = this_class.superclass while !this_class.nil?
        end
      end

      # Iterates over all defined attributes in a child => parent hierarchy,
      # and yields the name and entry for each.
      def each_attribute(&block)
        self_and_ancestors.select{ |klass| Attributes.registry[klass] }.each do |klass|
          Attributes.registry[klass].each{ |name, entry| block.call(name, entry) }
        end
      end

      # The default value can be one of the following:
      # - A symbol that is a method the instance responds to
      # - A symbol that is a method that the instance's tick responds to
      # - A Proc that is bound to the instance
      # - An immediate value (Integer, Float, Boolean, etc.)
      def default_value_for(entry)
        return instance_exec(&entry[:default]) if entry[:default].is_a?(Proc)
        return entry[:default] unless entry[:default].is_a?(Symbol)
        return send(entry[:default]) if respond_to?(entry[:default])
        return tick.send(entry[:default]) if tick.respond_to?(entry[:default])

        entry[:default]
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
          define_singleton_method(name) do
            return instance_variable_get(ivar_name) if instance_variable_defined?(ivar_name)

            # Sets the default value when accessed and ivar is not already set
            default_value_for(entry).tap { |value| instance_variable_set(ivar_name, value) }
          end
          define_singleton_method("#{name}=") { |value| instance_variable_set(ivar_name, value) }
        end
      end

      # Serializes keys that have been defined as serializeable attributes
      # Key values that are nil are omitted from the hash
      # @return [Hash] The serialized attributes as a Ruby Hash.
      def to_h
        {}.tap do |key_values|
          each_attribute do |name, entry|
            next unless entry[:key]

            value = send(name)
            next unless value

            key_values[entry[:key]] = value
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
