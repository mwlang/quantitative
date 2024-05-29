# frozen_string_literal: true

module Quant
  class Indicators
    class Pivots
      class Donchian < Pivot
        using Quant

        def st_period; min_period end
        def mt_period; half_period end
        def lt_period; max_period end

        def st_highs; @st_highs ||= [].max_size!(st_period) end
        def st_lows; @st_lows ||= [].max_size!(st_period) end
        def mt_highs; @mt_highs ||= [].max_size!(mt_period) end
        def mt_lows; @mt_lows ||= [].max_size!(mt_period) end
        def lt_highs; @lt_highs ||= [].max_size!(lt_period) end
        def lt_lows; @lt_lows ||= [].max_size!(lt_period) end

        def compute_bands
          st_highs << p0.high_price
          st_lows << p0.low_price
          mt_highs << p0.high_price
          mt_lows << p0.low_price
          lt_highs << p0.high_price
          lt_lows << p0.low_price

          p0.h1 = @st_highs.maximum
          p0.l1 = @st_lows.minimum

          p0.h2 = @mt_highs.maximum
          p0.l2 = @mt_lows.minimum

          p0.h3 = @lt_highs.maximum
          p0.l3 = @lt_lows.minimum
        end
      end
    end
  end
end
