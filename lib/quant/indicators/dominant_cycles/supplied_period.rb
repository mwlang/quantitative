# frozen_string_literal: true

module Quant
  module Indicators
    module DominantCycles
      # `SuppliedPeriod` — a dominant-cycle slot whose period is supplied
      # by the caller rather than computed from price data. The `compute`
      # method is intentionally a no-op; whatever sets `point.period` is
      # the period that downstream indicators reading `adaptive_period`
      # will see.
      #
      # Use this when you want a downstream indicator's lookback window
      # to come from somewhere other than the indicator's own cycle
      # detection — a fixed constant, an operator setting, a config
      # value, or a separate runtime process. Four canonical modes,
      # distinguished only by *who* sets the period and *when*:
      #
      # | Mode       | Period source                          | When set         | Example use case                          |
      # |------------|----------------------------------------|------------------|-------------------------------------------|
      # | Fixed      | Literal value at construction          | Once             | RSI(14), SMA(20) — classical lookbacks    |
      # | Manual     | Operator-mutable runtime setting       | On every read    | Settings page, Pool config tuning         |
      # | Configured | `Quant.config.indicators` symbol       | On every read    | Project-wide default lookback             |
      # | External   | Substrate written by another process   | Per-tick by collector | Tick-derived adaptive period (Fishy peak-count) |
      #
      # ## Mode 1: Fixed
      #
      # Period is a literal value, set once at construction, never
      # changes. The classical "RSI(14)" / "SMA(20)" shape.
      #
      #     Quant.config.indicators.dominant_cycle_kind = :supplied_period
      #     indicator = MyIndicator.new(series: series)
      #     indicator.dominant_cycle.p0.period = 14    # fixed lookback
      #
      # ## Mode 2: Manual (operator-tunable at runtime)
      #
      # Period is set from a value the operator changes via UI, config
      # file reload, settings page, etc. The slot reads whatever value
      # is current when the indicator runs.
      #
      #     point.period = pool.config.fetch(:lookback_window)
      #
      # When the operator updates `pool.config[:lookback_window]`, the
      # next tick sees the new value. No re-instantiation needed.
      #
      # ## Mode 3: Configured (Quant.config-resolved default)
      #
      # Period defaults to a symbol (`:half_period`) that resolves
      # through `Quant.config.indicators` at indicator construction
      # time. This was the original `HalfPeriod` usage — the parent
      # `Indicator#half_period` resolves to
      # `(min_period + max_period) / 2` from the active config.
      #
      # The default symbol mechanism resolves once per indicator
      # instance; if the operator mutates `Quant.config.indicators`
      # after construction, existing indicator instances continue
      # using the resolved-at-construction value. Construct a fresh
      # indicator to pick up the new config (or use Mode 2 / 4 if
      # you need true runtime tracking).
      #
      #     class SuppliedPeriodPoint < IndicatorPoint
      #       attribute :period, default: :half_period
      #     end
      #
      #     # consumer site — no explicit set; default symbol resolves:
      #     indicator.dominant_cycle.p0.period     # => 18 (resolved from config)
      #
      # ## Mode 4: External (runtime-supplied by a separate process)
      #
      # Period is supplied per-tick by a separate producer writing to
      # substrate. The integration site (collector, service, anywhere
      # downstream of the producer) reads the substrate and sets
      # `point.period` before consumers read `adaptive_period`.
      #
      # Example pattern: a producer computes a tick-stream peak-to-peak
      # period and writes it to substrate. A consuming indicator's
      # collector instance reads the substrate value and populates the
      # supplied-period slot:
      #
      #     period_seconds = substrate.read(platform, listing).period_seconds
      #     period_bars    = period_seconds / series.interval.to_seconds
      #     indicator.dominant_cycle.p0.period = period_bars
      #
      # The substrate-driven external mode is the load-bearing pattern
      # for tick-derived adaptive lookbacks — but the slot itself is
      # mode-agnostic; consumers compose any of the four modes per
      # their need.
      #
      # ## Why no-op `compute`?
      #
      # The `DominantCycle` framework's contract is that
      # `Indicator#dominant_cycle_indicator_class.compute` runs once per
      # tick, then consumers read `point.period`. `SuppliedPeriod`
      # short-circuits that — `compute` runs (no-op), and `point.period`
      # carries whatever the caller put there. This lets the polymorphic
      # DC dispatch (`Indicator#dominant_cycle`) treat externally-driven
      # period sources identically to algorithmically-computed ones.
      #
      # ## Default fallback
      #
      # When no caller sets `point.period`, the attribute default
      # (`:half_period`) provides safe behavior: downstream indicators
      # see the midpoint-of-min-max-period config value, which is what
      # they got pre-rename with `HalfPeriod`. Backward-compatible.
      #
      # Note: the default symbol `:half_period` refers to the
      # `Settings::Indicators#half_period` method (the `(max+min)/2`
      # attribute), NOT the deprecated `HalfPeriod` class. The method
      # is not deprecated and is unaffected by this rename.
      #
      # ## Migration from HalfPeriod (deprecated; removed in 0.9.0)
      #
      # Prior to 0.6.0 this class was named `HalfPeriod`. The old name
      # was descriptive of one resolved value (the midpoint of min/max
      # period in config) rather than the underlying capability (a slot
      # whose period is supplied externally). The rename clarifies that
      # the slot supports four equivalent modes — see table above.
      #
      # The old names continue to work through 0.8.x but emit Ruby
      # deprecation warnings via `Module#deprecate_constant`:
      #
      #     HalfPeriod      = SuppliedPeriod       # deprecated; warns at access
      #     HalfPeriodPoint = SuppliedPeriodPoint  # deprecated; warns at access
      #
      # The registry symbol `:half_period` continues to resolve to
      # `SuppliedPeriod` for `Quant.config.indicators.dominant_cycle_kind`
      # through 0.8.x; the resolver emits a one-time deprecation warning
      # per `Quant::Settings::Indicators` instance when `:half_period`
      # is the lookup key.
      #
      # **To migrate** (any 0.6.x or later):
      #
      #     # before:
      #     Quant.config.indicators.dominant_cycle_kind = :half_period
      #     point = Quant::Indicators::DominantCycles::HalfPeriodPoint.new(...)
      #
      #     # after:
      #     Quant.config.indicators.dominant_cycle_kind = :supplied_period
      #     point = Quant::Indicators::DominantCycles::SuppliedPeriodPoint.new(...)
      #
      # The point's `period` attribute default stays `:half_period` —
      # that's the resolved-via-config symbol (Mode 3) and a sensible
      # safe default; it is NOT the deprecated class name and is not
      # affected by the rename. Existing consumers see identical
      # runtime behavior.
      #
      # **Removal**: `HalfPeriod` / `HalfPeriodPoint` constants and the
      # `:half_period` registry alias are scheduled for removal in
      # quantitative 0.9.0. Migrate any time before then.
      class SuppliedPeriodPoint < Quant::Indicators::IndicatorPoint
        attribute :period, default: :half_period
      end

      class SuppliedPeriod < DominantCycle
        register name: :supplied_period

        def compute
          # No-Op — `period` is supplied by the caller (see class doc
          # for the four canonical supply modes).
        end
      end

      # Deprecated aliases — removed in 0.9.0. See `SuppliedPeriod`
      # class doc §Migration for the upgrade path.
      HalfPeriodPoint = SuppliedPeriodPoint
      HalfPeriod      = SuppliedPeriod

      deprecate_constant :HalfPeriod
      deprecate_constant :HalfPeriodPoint
    end
  end
end
