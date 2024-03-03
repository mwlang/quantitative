# frozen_string_literal: true

require_relative "high_pass_filters"
require_relative "butterworth_filters"
require_relative "universal_filters"
module Quant
  module Mixins
    module Filters
      include Mixins::HighPassFilters
      include Mixins::ButterworthFilters
      include Mixins::UniversalFilters
    end
  end
end
