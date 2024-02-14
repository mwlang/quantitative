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
array_of_floats = array_of_integers.map{ |int| int.to_f + (rand(1000) / 1000.0) }

unless [native(array_of_integers), foo_cached(array_of_integers), bar_cached(array_of_integers)].uniq.size == 1
  raise "Invalid results #{native(array_of_integers).inspect} != #{foo_cached(array_of_integers).inspect} != #{bar_cached(array_of_integers).inspect}"
end

perform name: "array of integers", array: array_of_integers
perform name: "array of floats", array: array_of_floats

# --------------------------------------------------------------------------------
# array of integers
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin22]
# Warming up --------------------------------------
#               native     1.000 i/100ms
#           foo cached    14.000 i/100ms
#           bar cached    14.000 i/100ms
# Calculating -------------------------------------
#               native      0.638 (± 0.0%) i/s -      4.000 in   6.270681s
#           foo cached    143.968 (± 2.1%) i/s -    728.000 in   5.059400s
#           bar cached    143.490 (± 1.4%) i/s -    728.000 in   5.074959s

# Comparison:
#           foo cached:      144.0 i/s
#           bar cached:      143.5 i/s - same-ish: difference falls within error
#               native:        0.6 i/s - 225.69x  slower

# --------------------------------------------------------------------------------
# array of floats
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin22]
# Warming up --------------------------------------
#               native     1.000 i/100ms
#           foo cached    13.000 i/100ms
#           bar cached    13.000 i/100ms
# Calculating -------------------------------------
#               native      0.074 (± 0.0%) i/s -      1.000 in  13.565938s
#           foo cached    131.565 (± 3.0%) i/s -    663.000 in   5.044145s
#           bar cached    132.079 (± 2.3%) i/s -    663.000 in   5.022804s

# Comparison:
#           bar cached:      132.1 i/s
#           foo cached:      131.6 i/s - same-ish: difference falls within error
#               native:        0.1 i/s - 1791.77x  slower