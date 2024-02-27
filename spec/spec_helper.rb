# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require 'simplecov-cobertura'
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

require "quantitative"
require "debug"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def fixture_path(sub_folder)
  File.join(File.expand_path(File.join(File.dirname(__FILE__), "fixtures")), sub_folder.to_s)
end

def fixture_filename(filename, sub_folder = nil)
  File.join fixture_path(sub_folder), filename
end
