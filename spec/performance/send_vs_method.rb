# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"

class Accumulator
  def initialize
    @sum = 0
  end

  def add(a, source:)
    @sum += a.send(source)
  end

  attr_reader :sum
end

def direct(array)
  accumulator = Accumulator.new
  array.each { |i| accumulator.add(i, source: :to_i) }
  accumulator.sum
end

def by_send(array)
  accumulator = Accumulator.new
  array.each { |i| accumulator.send(:add, i, source: :to_i) }
  accumulator.sum
end

def by_method(array)
  accumulator = Accumulator.new
  add = accumulator.method(:add)
  array.each { |i| add.call(i, source: :to_i) }
  accumulator.sum
end

def by_proc(array)
  accumulator = Accumulator.new
  add = proc{ |v, source| accumulator.add(v, source: source) }
  array.each { |i| add.call(i, :to_i) }
  accumulator.sum
end

def by_lambda(array)
  accumulator = Accumulator.new
  add = ->(v, source){ accumulator.add(v, source: source) }
  array.each { |i| add.call(i, :to_i) }
  accumulator.sum
end

def perform(name:, array:)
  puts "-" * 80, name, "-" * 80
  Benchmark.ips do |x|
    x.report("direct") { direct(array) }
    x.report("by_send") { by_send(array) }
    x.report("by_method") { by_method(array) }
    x.report("by_proc") { by_proc(array) }
    x.report("by_lambda") { by_lambda(array) }
    x.compare!
  end
end

array_of_strings = 50_000.times.map(&:to_s)
array_of_integers = 50_000.times.map(&:to_i)
array_of_floats = 50_000.times.map(&:to_f)
array_of_rationals = 50_000.times.map(&:to_r)

unless direct(array_of_strings) == direct(array_of_integers)
  raise "Invalid results"
end

unless direct(array_of_integers) == by_send(array_of_integers) &&
       by_send(array_of_integers) == by_method(array_of_integers) &&
       by_method(array_of_integers) == by_proc(array_of_integers) &&
       by_proc(array_of_integers) == by_lambda(array_of_integers)
  raise "Invalid results"
end

perform name: "array of integers", array: array_of_integers
perform name: "array of strings", array: array_of_strings
perform name: "array of floats", array: array_of_floats
perform name: "array of rationals", array: array_of_rationals

# --------------------------------------------------------------------------------
# array of integers
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin22]
# Warming up --------------------------------------
#               direct    76.000 i/100ms
#              by_send    71.000 i/100ms
#            by_method    13.000 i/100ms
#              by_proc    45.000 i/100ms
#            by_lambda    45.000 i/100ms
# Calculating -------------------------------------
#               direct    758.727 (± 0.9%) i/s -      3.800k in   5.008854s
#              by_send    723.848 (± 0.8%) i/s -      3.692k in   5.100900s
#            by_method    137.215 (± 1.5%) i/s -    689.000 in   5.022014s
#              by_proc    447.569 (± 0.4%) i/s -      2.250k in   5.027223s
#            by_lambda    449.643 (± 1.1%) i/s -      2.250k in   5.004549s

# Comparison:
#               direct:      758.7 i/s
#              by_send:      723.8 i/s - 1.05x  slower
#            by_lambda:      449.6 i/s - 1.69x  slower
#              by_proc:      447.6 i/s - 1.70x  slower
#            by_method:      137.2 i/s - 5.53x  slower

# --------------------------------------------------------------------------------
# array of strings
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin22]
# Warming up --------------------------------------
#               direct    45.000 i/100ms
#              by_send    43.000 i/100ms
#            by_method    12.000 i/100ms
#              by_proc    31.000 i/100ms
#            by_lambda    31.000 i/100ms
# Calculating -------------------------------------
#               direct    451.051 (± 1.3%) i/s -      2.295k in   5.088995s
#              by_send    439.470 (± 1.1%) i/s -      2.236k in   5.088506s
#            by_method    121.204 (± 0.8%) i/s -    612.000 in   5.050088s
#              by_proc    318.415 (± 1.6%) i/s -      1.612k in   5.063874s
#            by_lambda    318.692 (± 0.9%) i/s -      1.612k in   5.058734s

# Comparison:
#               direct:      451.1 i/s
#              by_send:      439.5 i/s - 1.03x  slower
#            by_lambda:      318.7 i/s - 1.42x  slower
#              by_proc:      318.4 i/s - 1.42x  slower
#            by_method:      121.2 i/s - 3.72x  slower

# --------------------------------------------------------------------------------
# array of floats
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin22]
# Warming up --------------------------------------
#               direct    72.000 i/100ms
#              by_send    69.000 i/100ms
#            by_method    13.000 i/100ms
#              by_proc    43.000 i/100ms
#            by_lambda    43.000 i/100ms
# Calculating -------------------------------------
#               direct    732.013 (± 1.1%) i/s -      3.672k in   5.016858s
#              by_send    694.337 (± 1.6%) i/s -      3.519k in   5.069481s
#            by_method    135.781 (± 2.2%) i/s -    689.000 in   5.076387s
#              by_proc    437.343 (± 0.9%) i/s -      2.193k in   5.014780s
#            by_lambda    436.517 (± 0.9%) i/s -      2.193k in   5.024236s

# Comparison:
#               direct:      732.0 i/s
#              by_send:      694.3 i/s - 1.05x  slower
#              by_proc:      437.3 i/s - 1.67x  slower
#            by_lambda:      436.5 i/s - 1.68x  slower
#            by_method:      135.8 i/s - 5.39x  slower

# --------------------------------------------------------------------------------
# array of rationals
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin22]
# Warming up --------------------------------------
#               direct    66.000 i/100ms
#              by_send    64.000 i/100ms
#            by_method    13.000 i/100ms
#              by_proc    40.000 i/100ms
#            by_lambda    41.000 i/100ms
# Calculating -------------------------------------
#               direct    663.035 (± 1.4%) i/s -      3.366k in   5.077514s
#              by_send    639.018 (± 1.4%) i/s -      3.200k in   5.008709s
#            by_method    131.913 (± 1.5%) i/s -    663.000 in   5.026697s
#              by_proc    413.032 (± 1.0%) i/s -      2.080k in   5.036389s
#            by_lambda    415.749 (± 1.0%) i/s -      2.091k in   5.029995s

# Comparison:
#               direct:      663.0 i/s
#              by_send:      639.0 i/s - 1.04x  slower
#            by_lambda:      415.7 i/s - 1.59x  slower
#              by_proc:      413.0 i/s - 1.61x  slower
#            by_method:      131.9 i/s - 5.03x  slower