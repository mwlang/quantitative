# frozen_string_literal: true

require "time"
require "date"
require "oj"
require "csv"
require "zeitwerk"

lib_folder = File.expand_path(File.join(File.dirname(__FILE__)))
quant_folder = File.join(lib_folder, "quant")

# Explicitly require module functions since Zeitwerk isn't configured, yet.
require_relative "quant/time_methods"
require_relative "quant/config"
require_relative "quant/experimental"
module Quant
  include TimeMethods
  include Config
  include Experimental
end

# Configure Zeitwerk to autoload the Quant module.
loader = Zeitwerk::Loader.for_gem
loader.push_dir(quant_folder, namespace: Quant)

loader.inflector.inflect "ohlc" => "OHLC"
loader.inflector.inflect "version" => "VERSION"

loader.setup

# Refinements aren't autoloaded by Zeitwerk, so we need to require them manually.
# %w(refinements).each do |sub_folder|
#   Dir.glob(File.join(quant_folder, sub_folder, "**/*.rb")).each { |fn| require fn }
# end

refinements_folder = File.join(quant_folder, "refinements")
indicators_folder = File.join(quant_folder, "indicators")

loader.eager_load_dir(refinements_folder)
loader.eager_load_dir(indicators_folder)
