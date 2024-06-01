# frozen_string_literal: true

module Quant
  module Mixins
    module Filters
      include Mixins::HighPassFilters
      include Mixins::ButterworthFilters
      include Mixins::UniversalFilters
    end
  end
end
