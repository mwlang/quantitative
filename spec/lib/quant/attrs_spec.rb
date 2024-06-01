# frozen_string_literal: true

module Experiment
  def self.registry
    @registry ||= {}
  end

  def self.register(klass, name, default)
    registry[klass] ||= {}
    registry[klass][name] = default
  end

  module InstanceMethods
    def initialize(...)
      initialize_attributes
      super(...)
    end

    def each_attribute(&block)
      klass = self.class
      loop do
        attributes = Experiment.registry[klass]
        break if attributes.nil?

        attributes.each{ |name, default| block.call(name, default) }
        klass = klass.superclass
      end
    end

    def initialize_attributes
      each_attribute do |name, default|
        ivar_name = "@#{name}"
        instance_variable_set(ivar_name, default)
        define_singleton_method(name) { instance_variable_get(ivar_name) }
        define_singleton_method("#{name}=") { |value| instance_variable_set(ivar_name, value) }
      end
    end

    def to_h
      {}.tap do |key_values|
        each_attribute do |name, _default|
          ivar_name = "@#{name}"
          value = instance_variable_get(ivar_name)
          key_values[name] = value if value
        end
      end
    end
  end

  module ClassMethods
    def bake(name, default)
      Experiment.register(self, name, default)
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.prepend(InstanceMethods)
  end
end

class Reaction
  include Experiment

  bake(:foo, "f")
end

class Salt < Reaction
  bake(:baz, "z")
end

class Pepper < Salt
  bake(:foobar, "foobar")
end

RSpec.describe "experiment" do
  it { expect(Reaction.new.to_h).to eq({ foo: "f" }) }
  it { expect(Salt.new.to_h).to eq({ baz: "z", foo: "f" }) }
  it { expect(Salt.new.tap{ |s| s.foo = "F" }.to_h).to eq({ baz: "z", foo: "F" }) }
  it { expect(Pepper.new.to_h).to eq({ baz: "z", foo: "f", foobar: "foobar" }) }

  # it { expect(Reaction.new.hello).to eq("hello") }
  # it { expect(Reaction.world).to eq("world") }
  # it { expect(Salt.world).to eq("world") }
  # it { Reaction.bar(:foo, "f"); expect(Reaction.foo).to eq({foo: "f"}) }
  # it { Reaction.bar(:foo, "f"); expect(Salt.foo).to eq({foo: "f", baz: "z"}) }
end
