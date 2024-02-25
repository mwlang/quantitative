# frozen_string_literal: true

module Quant
  module Errors
    # {Error} is the base class for all errors in the Quant gem.
    # It is a subclass of the Ruby {StandardError}.
    class Error < StandardError; end

    # {InvalidInterval} is raised when attempting to instantiate an
    # {Quant::Interval} with an invalid value.
    class InvalidInterval < Error; end

    # {InvalidResolution} is raised when attempting to instantiate
    # an {Quant::Resolution} with a resolution value that has not been defined.
    class InvalidResolution < Error; end

    # {ArrayMaxSizeError} is raised when attempting to set the +max_size+ on
    # the refined {Array} class to an invalid value or when attempting to
    # redefine the +max_size+ on the refined {Array} class.
    class ArrayMaxSizeError < Error; end

    # {AssetClassError} is raised when attempting to instantiate a
    # {Quant::Asset} with an attribute that is not a valid {Quant::Asset} attribute.
    class AssetClassError < Error; end

    # {DuplicateAttributesKeyError} is raised when attempting to define an
    # attribute with a key that has already been defined.
    class DuplicateAttributesKeyError < Error; end

    # {DuplicateAttributesNameError} is raised when attempting to define an
    # attribute with a name that has already been defined.
    class DuplicateAttributesNameError < Error; end
  end
end
