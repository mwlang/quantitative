# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"

def slice_sum(array, head, tail)
  array.slice(head, tail - head).sum
end

def slice_reduce(array, head, tail)
  array.slice(head, tail - head).reduce(0) { |sum, value| sum + value }
end

def index_reduce(array, head, tail)
  (head...tail).reduce(0) { |sum, idx| sum + array[idx] }
end

def perform(name:, array:, head:, tail:)
  puts "-" * 80, name, "-" * 80
  Benchmark.ips do |x|
    x.report("slice sum") { slice_sum(array, head, tail) }
    x.report("slice reduce") { slice_reduce(array, head, tail) }
    x.report("index reduce") { index_reduce(array, head, tail) }
    x.compare!
  end
end

array_of_integers = 50_000.times.map(&:to_i)

head = 10_000
tail = 25_000
unless [
  slice_reduce(array_of_integers, head, tail),
  slice_sum(array_of_integers, head, tail),
  index_reduce(array_of_integers, head, tail)].uniq.size == 1
  raise "Invalid results #{by_slicing(array_of_integers, head, tail)} != #{by_indexing(array_of_integers, head, tail)}"
end

perform name: "array of integers", array: array_of_integers, head: head, tail: tail

# --------------------------------------------------------------------------------
# array of integers
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin22]
# Warming up --------------------------------------
#                slice     7.040k i/100ms
#                index   166.000 i/100ms
# Calculating -------------------------------------
#                slice     69.715k (± 3.2%) i/s -    352.000k in   5.055413s
#                index      1.663k (± 2.2%) i/s -      8.466k in   5.092146s

# Comparison:
#                slice:    69715.1 i/s
#                index:     1663.4 i/s - 41.91x  slower
