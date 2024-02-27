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
      #
      # The challenge here is that we prepend this module to the class, and we are
      # initializing attributes before the owning class gets the opportunity to initialize
      # variables that we wanted to depend on with being able to define a default
      # value that could set default values from a +tick+ method.
      #
      # Ok for now.  May need to be more flexible in the future.  Alternative strategy could be
      # to lazy eval the default value the first time it is accessed.
      def initialize(*args, **kwargs)
        initialize_attributes(tick: kwargs[:tick])
        super(*args, **kwargs)
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

      # The default value can be one of the following:
      # - A symbol that is a method on the instance responds to
      # - A symbol that is a method that the instance's tick responds to
      # - A Proc that is bound to the instance
      # - An immediate value (Integer, Float, Boolean, etc.)
      def default_value_for(entry, new_tick)
        # let's not assume tick is always available/implemented
        # can get from instance or from initializer passed here as `new_tick`
        current_tick = new_tick
        current_tick ||= tick if respond_to?(:tick)

        if entry[:default].is_a?(Symbol) && respond_to?(entry[:default])
          send(entry[:default])

        elsif entry[:default].is_a?(Symbol) && current_tick.respond_to?(entry[:default])
          current_tick.send(entry[:default])

        elsif entry[:default].is_a?(Proc)
          instance_exec(&entry[:default])

        else
          entry[:default]
        end
      end

      # Initializes the defined attributes with default values and
      # defines accessor methods for each attribute.
      # If a child class redefines a parent's attribute, the child's
      # definition will be used.
      def initialize_attributes(tick:)
        each_attribute do |name, entry|
          # use the child's definition, skipping the parent's
          next if respond_to?(name)

          ivar_name = "@#{name}"
          instance_variable_set(ivar_name, default_value_for(entry, tick))
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
