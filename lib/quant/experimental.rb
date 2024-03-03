# frozen_string_literal: true

module Quant
  module Experimental
    def self.tracker
      @tracker ||= {}
    end
  end

  def self.experimental(message)
    return if defined?(RSpec)
    return if Experimental.tracker[caller.first]

    Experimental.tracker[caller.first] = message

    calling_method = caller.first.scan(/`([^']*)/)[0][0]
    full_message = "EXPERIMENTAL: #{calling_method.inspect}: #{message}\nsource location: #{caller.first}"
    puts full_message
  end
end
