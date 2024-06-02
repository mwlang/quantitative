module Quant
  module Indicators
    class EmaPoint < IndicatorPoint
      attribute :ss_dc_period, default: :input
      attribute :ss_half_dc_period, default: :input
      attribute :ss_micro_period, default: :input
      attribute :ss_min_period, default: :input
      attribute :ss_max_period, default: :input

      attribute :ema_dc_period, default: :input
      attribute :ema_half_dc_period, default: :input
      attribute :ema_micro_period, default: :input
      attribute :ema_min_period, default: :input
      attribute :ema_max_period, default: :input

      attribute :osc_dc_period, default: 0.0
      attribute :osc_half_dc_period, default: 0.0
      attribute :osc_micro_period, default: 0.0
      attribute :osc_min_period, default: 0.0
      attribute :osc_max_period, default: 0.0
    end

    class Ema < Indicator
      register name: :ema

      def alpha(period)
        bars_to_alpha(period)
      end

      def half_dc_period
        dc_period / 2
      end

      def compute_super_smoothers
        p0.ss_dc_period = super_smoother :input, previous: :ss_dc_period, period: dc_period
        p0.ss_half_dc_period = super_smoother :input, previous: :ss_half_dc_period, period: half_dc_period
        p0.ss_micro_period = super_smoother :input, previous: :ss_micro_period, period: micro_period
        p0.ss_min_period = super_smoother :input, previous: :ss_min_period, period: min_period
        p0.ss_max_period = super_smoother :input, previous: :ss_max_period, period: max_period
      end

      def compute_emas
        p0.ema_dc_period = ema :input, previous: :ema_dc_period, period: dc_period
        p0.ema_half_dc_period = ema :input, previous: :ema_half_dc_period, period: half_dc_period
        p0.ema_micro_period = ema :input, previous: :ema_micro_period, period: micro_period
        p0.ema_min_period = ema :input, previous: :ema_min_period, period: min_period
        p0.ema_max_period = ema :input, previous: :ema_max_period, period: max_period
      end

      def compute_oscillators
        p0.osc_dc_period = p0.ss_dc_period - p0.ema_dc_period
        p0.osc_half_dc_period = p0.ss_half_dc_period - p0.ema_half_dc_period
        p0.osc_micro_period = p0.ss_micro_period - p0.ema_micro_period
        p0.osc_min_period = p0.ss_min_period - p0.ema_min_period
        p0.osc_max_period = p0.ss_max_period - p0.ema_max_period
      end

      def compute
        compute_super_smoothers
        compute_emas
        compute_oscillators
      end
    end
  end
end