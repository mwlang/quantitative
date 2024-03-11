# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Attributes do
  def deregister_class(klass)
    Quant::Attributes.deregister(klass)
  rescue Quant::Errors::DuplicateAttributesKeyError
    # ignore since we're cleaning up
  end

  let(:original_class) do
    Class.new.tap do |klass|
      klass.include Quant::Attributes
      klass.attribute :foo
      klass.attribute :bar, key: "baz"
      klass.attribute :foobar, key: "fb", default: "foobar"
    end
  end
  let(:another_class) do
    Class.new.tap do |klass|
      klass.include Quant::Attributes
      klass.attribute :foo, default: "foo", key: "foo"
      klass.attribute :baz, key: "bar"
      klass.attribute :foobar, key: "fb2", default: "foobar2"
    end
  end

  after do
    deregister_class(another_class)
    deregister_class(original_class)
  end

  context "is extensible" do
    subject { original_class.new }

    it { is_expected.to be_a(original_class) }
    it { expect(subject.foo).to be_nil }
    it { expect(subject.bar).to be_nil }
    it { expect(subject.foobar).to eq("foobar") }
    it { is_expected.to respond_to(:foo) }
    it { is_expected.to respond_to(:foo=) }
    it { is_expected.to respond_to(:bar) }
    it { is_expected.to respond_to(:bar=) }
    it { is_expected.to respond_to(:foobar) }
    it { is_expected.to respond_to(:foobar=) }
    it { is_expected.to respond_to(:to_h) }

    it "sets default values" do
      expect(subject.foo).to be_nil
      expect(subject.bar).to be_nil
      expect(subject.foobar).to eq("foobar")
      expect(subject.to_h).to eq({ "fb" => "foobar" })
    end

    it "sets values" do
      subject.foo = "foo"
      subject.bar = "bar"
      expect(subject.foo).to eq("foo")
      expect(subject.bar).to eq("bar")
      expect(subject.to_h).to eq({ "baz" => "bar", "fb" => "foobar" })
    end
  end

  context "defaults as symbols" do
    let(:class_with_defaults) do
      Class.new.tap do |klass|
        klass.include Quant::Attributes
        klass.attribute :foo, default: :high_price
        klass.attribute :ticky, default: :oc2
        klass.attribute :symbolical, default: :a_symbol
        klass.attribute :diabolical
        klass.attribute :bar, default: 99
        klass.attribute :baz, default: -> { high_price + 5.0 }
        klass.define_method(:high_price) { 100 }
        klass.define_method(:tick) { Quant::Ticks::Spot.new(price: 25) }
      end
    end

    after do
      deregister_class(class_with_defaults)
    end

    subject { class_with_defaults.new }

    it "sets defaults" do
      expect(subject.foo).to eq(100)
      expect(subject.baz).to eq(105)
      expect(subject.bar).to eq(99)
      expect(subject.ticky).to eq(25)
      expect(subject.symbolical).to eq(:a_symbol)
      expect(subject.diabolical).to be_nil
    end

    it "can replace defaults" do
      subject.foo = :foo
      subject.baz = 10_000
      subject.symbolical = :another_symbol
      subject.diabolical = "666"

      expect(subject.foo).to eq(:foo)
      expect(subject.baz).to eq(10_000)
      expect(subject.symbolical).to eq(:another_symbol)
      expect(subject.diabolical).to eq("666")
    end
  end

  context "inheritance" do
    let(:parent_class) do
      Class.new.tap do |klass|
        klass.include Quant::Attributes
        klass.attribute :foo, key: "foo", default: "foo"
        klass.attribute :bar, default: "not serialized"
      end
    end
    let(:child_class) do
      Class.new(parent_class).tap do |klass|
        klass.attribute :bar, key: "bar", default: "bar"
      end
    end

    after do
      deregister_class(child_class)
      deregister_class(parent_class)
    end

    subject { child_class.new }

    it { expect(parent_class.new.foo).to eq("foo") }
    it { expect(parent_class.new.bar).to eq("not serialized") }
    it { expect(parent_class.new.to_h).to eq({ "foo" => "foo" }) }
    it { expect(parent_class.new.to_json).to eq("{\"foo\":\"foo\"}") }

    it { expect(child_class.new.foo).to eq("foo") }
    it { expect(child_class.new.bar).to eq("bar") }
    it { expect(child_class.new.to_h).to eq({ "bar" => "bar", "foo" => "foo" }) }
    it { expect(child_class.new.to_json).to eq("{\"bar\":\"bar\",\"foo\":\"foo\"}") }

    it "child does not collide with parent" do
      parent = parent_class.new
      child = child_class.new
      parent.foo = "parent"
      child.foo = "child"
      expect(parent.foo).to eq("parent")
      expect(child.foo).to eq("child")
      expect(parent.to_h).to eq({ "foo" => "parent" })
      expect(child.to_h).to eq({ "bar" => "bar", "foo" => "child" })
    end
  end

  context "scopes are sane across two classes" do
    subject(:original) { original_class.new }
    subject(:another) { another_class.new }

    after do
      deregister_class(original_class)
      deregister_class(another_class)
    end

    it { expect(original).to be_a(original_class) }
    it { expect(another).to be_a(another_class) }
    it { expect(original.foo).to be_nil }
    it { expect(another.foo).to eq("foo") }
    it { expect(original.bar).to be_nil }
    it { expect{ another.bar }.to raise_error NoMethodError }
    it { expect(original.foobar).to eq("foobar") }
    it { expect(another.foobar).to eq("foobar2") }
    it { expect(original.to_h).to eq({ "fb" => "foobar" }) }
    it { expect(another.to_h).to eq({ "fb2" => "foobar2", "foo" => "foo" }) }

    it "sets values" do
      original.foo = "foo"
      another.foo = "oof"
      original.foobar = "baz"
      another.foobar = "zab"
      expect(original.foo).to eq("foo")
      expect(another.foo).to eq("oof")
      expect(original.to_h).to eq({ "fb" => "baz" })
      expect(another.to_h).to eq({ "fb2" => "zab", "foo" => "oof" })
    end
  end

  context "disallows duplicate keys" do
    let(:class_with_unique_keys) do
      Class.new.tap do |klass|
        klass.include Quant::Attributes
        klass.attribute :foo
        klass.attribute :bar, key: "foo"
      end
    end

    let(:class_with_duplicate_keys) do
      Class.new.tap do |klass|
        klass.include Quant::Attributes
        klass.attribute :foo, key: "foo"
        klass.attribute :bar, key: "foo"
      end
    end

    let(:class_with_duplicate_names) do
      Class.new.tap do |klass|
        klass.include Quant::Attributes
        klass.attribute :foo
        klass.attribute :foo
      end
    end

    it "a serialized key with same name as non-serialized attribute name" do
      class_with_unique_keys = Class.new.tap do |klass|
        klass.include Quant::Attributes
        klass.attribute :foo
        klass.attribute :bar, key: "foo"
      end

      expect { class_with_unique_keys }.not_to raise_error
      deregister_class(class_with_unique_keys)
    end

    it "a serialized key defined twice" do
      class_with_duplicate_keys = Class.new
      class_with_duplicate_keys.include Quant::Attributes
      class_with_duplicate_keys.attribute(:foo, key: "foo")
      expect { class_with_duplicate_keys.attribute(:bar, key: "foo") }.to \
        raise_error(Quant::Errors::DuplicateAttributesKeyError)

      deregister_class(class_with_duplicate_keys)
    end

    it "an attribute defined twice" do
      expect { class_with_duplicate_names }.not_to raise_error

      deregister_class(class_with_duplicate_names)
    end
  end
end
