# frozen_string_literal: true

require "time"
require "date"
require "oj"
require "csv"

lib_folder = File.expand_path(File.join(File.dirname(__FILE__)))
quant_folder = File.join(lib_folder, "quant")

# require top-level files
Dir.glob(File.join(quant_folder, "*.rb")).each { |fn| require fn }

# require sub-folders and their sub-folders
%w(refinements mixins statistics settings ticks indicators).each do |sub_folder|
  Dir.glob(File.join(quant_folder, sub_folder, "**/*.rb")).each { |fn| require fn }
end
