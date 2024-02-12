# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"

class FooArray < Array
  def initialize(...)
    super(...)
    @minimum = nil
    @maximum = nil
  end

  def <<(value)
    @minimum = value if @minimum.nil? || @minimum > value
    @maximum = value if @maximum.nil? || @maximum < value
    super
  end

  def minmax
    empty? ? [nil, nil] : [@minimum, @maximum]
  end
end

class BarArray < FooArray
  def <<(value)
    @minimum = [@minimum, value].min rescue value
    @maximum = [@maximum, value].max rescue value
    super
  end
end

# purposely structured to push a value and call minmax each time as this is most common
# use case in the library
def native(array)
  new_array = []
  array.each { |v| new_array << v; new_array.minmax }
end

# purposely structured to push a value and call minmax each time as this is most common
# use case in the library
def foo_cached(array)
  new_array = FooArray.new
  array.each { |v| new_array << v; new_array.minmax }
end

def bar_cached(array)
  new_array = FooArray.new
  array.each { |v| new_array << v; new_array.minmax }
end

def perform(name:, array:)
  puts "-" * 80, name, "-" * 80
  Benchmark.ips do |x|
    x.report("native") { native(array) }
    x.report("foo cached") { foo_cached(array) }
    x.report("bar cached") { bar_cached(array) }
    x.compare!
  end
end

array_of_integers = 50_000.times.map { rand(1..100_000) }

unless [native(array_of_integers), foo_cached(array_of_integers), bar_cached(array_of_integers)].uniq.size == 1
  raise "Invalid results #{native(array_of_integers).inspect} != #{foo_cached(array_of_integers).inspect} != #{bar_cached(array_of_integers).inspect}"
end

perform name: "array of integers", array: array_of_integers

# --------------------------------------------------------------------------------
# array of integers
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin22]
# Warming up --------------------------------------
#               native     1.000 i/100ms
#           foo cached    14.000 i/100ms
#           bar cached    14.000 i/100ms
# Calculating -------------------------------------
#               native      0.636 (± 0.0%) i/s -      4.000 in   6.288797s
#           foo cached    146.754 (± 1.4%) i/s -    742.000 in   5.057460s
#           bar cached    145.638 (± 2.1%) i/s -    728.000 in   5.000705s

# Comparison:
#           foo cached:      146.8 i/s
#           bar cached:      145.6 i/s - same-ish: difference falls within error
#               native:        0.6 i/s - 230.73x  slower
