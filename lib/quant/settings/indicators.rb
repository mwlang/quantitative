# frozen_string_literal: true

module Quant
  module Settings
    # Indicator settings provide a way to configure the default settings for indicators.
    # Many of the indicators are built in adaptive measuring of the dominant cycle and these settings
    # provide a way to configure your choices for the indicators.  The default values come from various
    # papers and books on the subject of technical analysis by John Ehlers where he variously suggests
    # a minimum period of 8 or 10 and a max period of 48.
    #
    # The half period is the average of the max_period and min_period.  It is read-only and always computed
    # relative to `min_period` and `max_period`.
    #
    # The micro period comes from Ehler's writings on Swami charts and auto-correlation computations, which
    # is a period of 3 bars.  It is useful enough in various indicators to be its own setting.
    #
    # The dominant cycle kind is the kind of dominant cycle to use in the indicator.  The default is +:settings+
    # which means the dominant cycle is whatever the +max_period+ is set to.  It is not adaptive when configured
    # this way.  The other kinds are adaptive and are computed from the series data.  The choices are:
    # * +:half_period+  - the half_period is the dominant cycle and is not adaptive
    # * +:band_pass+ - The zero crossings of the band pass filter are used to compute the dominant cycle
    # * +:auto_correlation_reversal+ - The dominant cycle is computed from the auto-correlation of the series.
    # * +:homodyne+ - The dominant cycle is computed from the homodyne discriminator.
    # * +:differential+ - The dominant cycle is computed from the differential discriminator.
    # * +:phase_accumulator+ - The dominant cycle is computed from the phase accumulator.
    #
    # All of the above are adaptive and are computed from the series data and are described in John Ehlers' books
    # and published papers.
    #
    # Pivot kinds are started as the classic pivot points and then expanded to include other kinds of bands that
    # follow along with price action such as Donchian channels, Fibonacci bands, Bollinger bands, Keltner bands,
    # etc.  The choices are as follows:
    # * +:pivot+ - Classic pivot points
    # * +:donchian+ - Donchian channels
    # * +:fibbonacci+ - Fibonacci bands
    # * +:woodie+ - Woodie's pivot points
    # * +:classic+ - Classic pivot points
    # * +:camarilla+ - Camarilla pivot points
    # * +:demark+ - Demark pivot points
    # * +:murrey+ - Murrey math pivot points
    # * +:keltner+ - Keltner bands
    # * +:bollinger+ - Bollinger bands
    # * +:guppy+ - Guppy bands
    # * +:atr+ - ATR bands
    #
    class Indicators
      # Returns an instance of the settings for indicators configured with defaults derived from
      # defined constants in the +Quant::Settings+ module.
      def self.defaults
        new
      end

      attr_reader :max_period, :min_period, :half_period
      attr_accessor :micro_period, :dominant_cycle_kind, :pivot_kind

      def initialize(**settings)
        @max_period = settings[:max_period] || Settings::MAX_PERIOD
        @min_period = settings[:min_period] || Settings::MIN_PERIOD
        @half_period = settings[:half_period] || compute_half_period
        @micro_period = settings[:micro_period] || Settings::MICRO_PERIOD

        @dominant_cycle_kind = settings[:dominant_cycle_kind] || Settings::DOMINANT_CYCLE_KINDS.first
        @pivot_kind = settings[:pivot_kind] || Settings::PIVOT_KINDS.first
      end

      def apply_settings(**settings)
        @max_period = settings.fetch(:max_period, @max_period)
        @min_period = settings.fetch(:min_period, @min_period)
        compute_half_period
        @micro_period = settings.fetch(:micro_period, @micro_period)
        @dominant_cycle_kind = settings.fetch(:dominant_cycle_kind, @dominant_cycle_kind)
        @pivot_kind = settings.fetch(:pivot_kind, @pivot_kind)
      end

      def max_period=(value)
        (@max_period = value).tap { compute_half_period }
      end

      def min_period=(value)
        (@min_period = value).tap { compute_half_period }
      end

      def compute_half_period
        @half_period = (max_period + min_period) / 2
      end
    end
  end
end
