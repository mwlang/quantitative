# frozen_string_literal: true

require "time"
require "date"
require "oj"

lib_folder = File.expand_path(File.join(File.dirname(__FILE__)))
quant_folder = File.join(lib_folder, "quant")

# require top-level files
Dir.glob(File.join(quant_folder, "*.rb")).each { |fn| require fn }

# require sub-folders and their sub-folders
%w(refinements ticks).each do |sub_folder|
  Dir.glob(File.join(quant_folder, sub_folder, "**/*.rb")).each { |fn| require fn }
end
