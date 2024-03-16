# frozen_string_literal: true

module Quant
  module Settings
    MAX_PERIOD = 48
    MIN_PERIOD = 10
    HALF_PERIOD = (MAX_PERIOD + MIN_PERIOD) / 2
    MICRO_PERIOD = 3

    PIVOT_KINDS = %i(
      pivot
      donchian
      fibbonacci
      woodie
      classic
      camarilla
      demark
      murrey
      keltner
      bollinger
      guppy
      atr
    ).freeze

    DOMINANT_CYCLE_KINDS = %i(
      half_period
      band_pass
      auto_correlation_reversal
      homodyne
      differential
      phase_accumulator
    ).freeze

    # ---- Risk Management Ratio Settings ----
    #   Risk    Reward    Breakeven Win Rate %
    #     50         1            98%
    #     10         1            91%
    #      5         1            83%
    #      3         1            75%
    #      2         1            67%
    #      1         1            50%
    #      1         2            33%
    #      1         3            25%
    #      1         5            17%
    #      1        10             9%
    #      1        50             2%
    PROFIT_TARGET_PCT = 0.03
    STOP_LOSS_PCT = 0.01
  end
end
