# frozen_string_literal: true

module Quant
  # {Quant::Experimental} is an alert emitter for experimental code paths.
  # It will typically be used for new indicators or computations that are not yet
  # fully vetted or tested.
  module Experimental
    def self.tracker
      @tracker ||= {}
    end

    def self.rspec_defined?
      defined?("RSpec")
    end
  end

  module_function

  def experimental(message)
    return if Experimental.rspec_defined?
    return if Experimental.tracker[caller.first]

    Experimental.tracker[caller.first] = message

    calling_method = caller.first.scan(/`([^']*)/)[0][0]
    full_message = "EXPERIMENTAL: #{calling_method.inspect}: #{message}\nsource location: #{caller.first}"
    puts full_message
  end
end
