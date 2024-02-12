require "bundler/setup"
require 'benchmark/ips'

class Accumulator
  def initialize
    @sum = 0
  end

  def add(a, source:)
    @sum += a.send(source)
  end

  def sum
    @sum
  end
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
  puts '-' * 80, name, '-' * 80
  Benchmark.ips do |x|
    x.report('direct') { direct(array) }
    x.report('by_send') { by_send(array) }
    x.report('by_method') { by_method(array) }
    x.report('by_proc') { by_proc(array) }
    x.report('by_lambda') { by_lambda(array) }
    x.compare!
  end
end

array_of_strings = 50_000.times.map(&:to_s)
array_of_integers = 50_000.times.map(&:to_i)
array_of_floats = 50_000.times.map(&:to_f)
array_of_rationals = 50_000.times.map(&:to_r)

unless direct(array_of_strings) == direct(array_of_integers)
  raise 'Invalid results'
end

unless direct(array_of_integers) == by_send(array_of_integers) &&
    by_send(array_of_integers) == by_method(array_of_integers) &&
    by_method(array_of_integers) == by_proc(array_of_integers) &&
    by_proc(array_of_integers) == by_lambda(array_of_integers)
  raise 'Invalid results'
end

perform name: "array of integers", array: array_of_integers
perform name: "array of strings", array: array_of_strings
perform name: "array of floats", array: array_of_floats
perform name: "array of rationals", array: array_of_rationals

=begin
=end