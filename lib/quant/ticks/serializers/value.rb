# frozen_string_literal: true

module Quant
  module Ticks
    module Serializers
      module Value
        module_function

        def to_h(instance)
          { "iv" => instance.interval.to_s,
            "ct" => instance.close_timestamp.to_i,
            "cp" => instance.close_price,
            "bv" => instance.base_volume,
            "tv" => instance.target_volume }
        end

        def to_json(instance)
          Oj.dump to_h(instance)
        end
      end
    end
  end
end
