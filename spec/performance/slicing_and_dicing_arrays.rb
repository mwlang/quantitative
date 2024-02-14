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
array_of_floats = 50_000.times.map(&:to_f)

head = 10_000
tail = 25_000
unless [
  slice_reduce(array_of_integers, head, tail),
  slice_sum(array_of_integers, head, tail),
  index_reduce(array_of_integers, head, tail)].uniq.size == 1
  raise "Invalid results #{by_slicing(array_of_integers, head, tail)} != #{by_indexing(array_of_integers, head, tail)}"
end

perform name: "array of integers", array: array_of_integers, head: head, tail: tail
perform name: "array of floats", array: array_of_floats, head: head, tail: tail

# --------------------------------------------------------------------------------
# array of integers
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin22]
# Warming up --------------------------------------
#            slice sum     7.038k i/100ms
#         slice reduce   212.000 i/100ms
#         index reduce   202.000 i/100ms
# Calculating -------------------------------------
#            slice sum     70.662k (± 0.3%) i/s -    358.938k in   5.079706s
#         slice reduce      2.139k (± 0.6%) i/s -     10.812k in   5.054772s
#         index reduce      2.018k (± 0.4%) i/s -     10.100k in   5.004402s

# Comparison:
#            slice sum:    70661.6 i/s
#         slice reduce:     2139.0 i/s - 33.03x  slower
#         index reduce:     2018.3 i/s - 35.01x  slower

# --------------------------------------------------------------------------------
# array of floats
# --------------------------------------------------------------------------------
# ruby 3.3.0 (2023-12-25 revision 5124f9ac75) +YJIT [arm64-darwin22]
# Warming up --------------------------------------
#            slice sum     2.962k i/100ms
#         slice reduce   188.000 i/100ms
#         index reduce   179.000 i/100ms
# Calculating -------------------------------------
#            slice sum     29.527k (± 1.2%) i/s -    148.100k in   5.016487s
#         slice reduce      1.874k (± 1.5%) i/s -      9.400k in   5.016972s
#         index reduce      1.801k (± 1.1%) i/s -      9.129k in   5.070219s

# Comparison:
#            slice sum:    29527.0 i/s
#         slice reduce:     1874.1 i/s - 15.76x  slower
#         index reduce:     1800.7 i/s - 16.40x  slower