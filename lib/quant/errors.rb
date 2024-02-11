# frozen_string_literal: true

module Quant
  class Error < StandardError; end
  class InvalidInterval < Error; end
  class InvalidResolution < Error; end
end
