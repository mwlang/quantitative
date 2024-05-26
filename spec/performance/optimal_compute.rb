# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "quantitative"

# This test ensures we are only computing each indicator, at most, once per tick per input source.
# Indicators that utilized dominant cycle indicators originally were computing the dominant cycle
# for each and every indicator.  This test was used to count number of calls to the compute!
# method and compare against number of ticks in the series.

class ComputeInspector
  def self.instance
    @instance ||= new
  end

  def self.stats
    instance.stats
  end

  attr_reader :stats

  def initialize
    @stats = Hash.new { |h,k| h[k] = 0 }
  end

  def self.start
    instance.start
  end

  def self.finish
    instance.finish
  end

  def start
    @stats.clear
    @trace = TracePoint.new(:call) do |tp|
      next unless tp.defined_class.to_s =~ /Quant/
      next unless %i(assign_series! compute).include? tp.method_id

      key = "#{tp.defined_class}##{tp.method_id}:#{tp.lineno}"
      @stats[key] += 1
    end
    @trace.enable
  end

  def finish
    @trace.disable
    puts "-" * 80
    pp @stats
    puts "-" * 80
  end
end

symbol = "AAPL"
fixtures_folder = File.expand_path File.join(File.dirname(__FILE__), "..", "fixtures", "series")
filename = File.join(fixtures_folder, "AAPL-19990104_19990107.txt")
unless File.exist?(filename)
  puts "file #{filename} does not exist"
  exit
end

puts "loading #{filename}..."

ComputeInspector.start

series = Quant::Series.from_file(filename:, symbol:, interval: "1d")
series.indicators.oc2.dominant_cycle.map(&:itself)
series.indicators.oc2.mesa.map(&:itself)
series.indicators.oc2.ping.map(&:itself)
series.limit_iterations(0, 2).indicators.oc2.atr.map(&:itself)

ComputeInspector.finish

if ComputeInspector.stats.values.all? { |count| count == series.ticks.size }
  puts "SUCCESS: All indicators computed once per tick!"
else
  puts "ERROR: Indicators computed more than once per tick!"
end
puts "Ticks loaded: %i" % series.ticks.size
