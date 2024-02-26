# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"

class Point
  attr_reader :value
  attr_accessor :ss

  def initialize(value)
    @value = value
    @ss = value
  end
end

# Does not work - hits FloatDomainError: Infinity
def super_smoother(source, p0, p1, p2, p3, period:, previous: :ss)
  raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

  k = Math.exp(-Math.sqrt(2) * Math::PI / period)
  coef3 = -k**2
  coef2 = (2.0 * k * Math.cos(Math.sqrt(2) * (Math::PI / 2) / period))
  coef1 = 1.0 - coef2 - coef3

  v0 = p0.send(source)
  v1 = p1.send(previous)
  v2 = p2.send(previous)
  ((coef1 * (v0 + v1)) / 2.0 + (coef2 * v1) + (coef3 * v2)).to_f
end

def two_pole_super_smooth(source, p0, p1, p2, p3, period:, previous: :ss)
  raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)

  radians = Math::PI * Math.sqrt(2) / period
  a1 = Math.exp(-radians)

  coef2 = 2.0 * a1 * Math.cos(radians)
  coef3 = -a1 * a1
  coef1 = 1.0 - coef2 - coef3

  v0 = (p0.send(source) + p1.send(source))/2.0
  v1 = p2.send(previous)
  v2 = p3.send(previous)
  (coef1 * v0) + (coef2 * v1) + (coef3 * v2)
end

def ss_a(array)
  array.each_cons(4) do |p0, p1, p2, p3|
    p3.ss = super_smoother(:value, p0, p1, p2, p3, period: 25)
  end
end

def ss_b(array)
  array.each_cons(4) do |p0, p1, p2, p3|
    p3.ss = two_pole_super_smooth(:value, p0, p1, p2, p3, period: 25)
  end
end

def perform(name:, array:)
  puts "-" * 80, name, "-" * 80
  Benchmark.ips do |x|
    x.report("a") { ss_a(array) }
    x.report("b") { ss_b(array) }
    x.compare!
  end
end

array_of_integers = 50_000.times.map { rand(1..100_000) }
array_of_floats = array_of_integers.map{ |i| Point.new((i + rand(1000) / 1000.0)) }

perform name: "array of floats", array: array_of_floats

# --------------------------------------------------------------------------------
# array of floats
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin22]
# Warming up --------------------------------------
#                    a     2.000 i/100ms
#                    b     3.000 i/100ms
# Calculating -------------------------------------
#                    a     26.391 (± 7.6%) i/s -    132.000 in   5.025029s
#                    b     37.349 (± 5.4%) i/s -    189.000 in   5.072801s

# Comparison:
#                    b:       37.3 i/s
#                    a:       26.4 i/s - 1.42x  slower

# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# array of floats (with YJIT)
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin22]
# Warming up --------------------------------------
#                    a     2.000 i/100ms
#                    b     4.000 i/100ms
# Calculating -------------------------------------
#                    a     33.681 (± 5.9%) i/s -    168.000 in   5.007776s
#                    b     44.470 (± 4.5%) i/s -    224.000 in   5.054830s

# Comparison:
#                    b:       44.5 i/s
#                    a:       33.7 i/s - 1.32x  slower
