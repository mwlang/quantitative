# frozen_string_literal: true

require "debug"
require "test-prof"

TestProf.configure do |config|
  # the directory to put artifacts (reports) in ("tmp/test_prof" by default)
  config.output_dir = "tmp/test_prof"

  # use unique filenames for reports (by simply appending current timestamp)
  config.timestamps = true

  # color output
  config.color = true

  # where to write logs (defaults)
  config.output = $stdout
end

require "simplecov"
require "simplecov-cobertura"

SimpleCov.start do
  add_filter "/spec/"
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ])
end

require "quantitative"

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
  File.join(File.expand_path(__dir__), "fixtures", sub_folder.to_s)
end

def fixture_filename(filename, sub_folder = nil)
  File.join fixture_path(sub_folder), filename
end

support_folder = File.expand_path(__dir__)
Dir[File.join(support_folder, "support", "**", "*.rb")].each { |f| require f }