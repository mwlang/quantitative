# Changelog

All notable changes to `quantitative` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.5.0] — 2026-05-22

### Changed (breaking)

- **`Quant::AssetClass::CLASSES` renamed `:treasury_note` → `:treasury`.** The single `:treasury` symbol now covers the full US-government-debt family (bills, notes, bonds, TIPS). Maturity becomes listing metadata, not an AssetClass distinction. Breaking for consumers that exhaustively switch on the `CLASSES` set or pattern-match on `:treasury_note`.

  Migration: `s/:treasury_note/:treasury/g` across consumer code. Where maturity-aware behavior is needed (e.g., yield-curve segmentation), consult the listing's metadata rather than the AssetClass label.

### Added

- `Quant::AssetClass::CLASSES` gains six new entries: `:adr, :cash, :etn, :forward, :swap, :warrant`. Final catalog is 19 entries: `adr, bond, cash, commodity, cryptocurrency, etf, etn, forex, forward, future, mbs, mutual_fund, option, preferred_stock, reit, stock, swap, treasury, warrant`.
- Per-class spec coverage in `spec/lib/quant/asset_class_spec.rb` — each catalog entry is `valid?`, the 19-count invariant is asserted, and `:treasury_note` rejection is a regression guard against re-introducing the retired symbol.

---

## [0.4.1] — 2026-05

### Fixed

- **`Quant::Ticks::OHLC#initialize` and `Quant::Ticks::Spot#initialize` now preserve fractional volumes as `Float`.** A prior regression in both classes coerced `@base_volume` and `@target_volume` via `.to_i`, silently truncating fractional values to integers — a serious correctness issue for crypto markets (and any other domain where fractional base/target volumes are normal, such as fractional-share trading and many futures markets). For example, a kline with `base_volume: 0.12345` was previously stored as `0`. Existing spec assertions used `eq(2.0)` which masked the regression because Ruby's `==` coerces `2 == 2.0 → true`; the values *appeared* correct in tests while being silently truncated in production. Both initializers now coerce via `.to_f`. Trade count (`@trades`) continues to use `.to_i` as it is genuinely an integer.

  Affected files:
  - `lib/quant/ticks/ohlc.rb` (lines 51–52)
  - `lib/quant/ticks/spot.rb` (lines 46–47)

  Backwards compatibility: this is a behavior change for callers reading `tick.base_volume` / `tick.target_volume`. Code that did `volume == 2` continues to work (Ruby coerces). Code that did `volume.is_a?(Integer)` will see `false` where it previously saw `true`; such code was implicitly relying on the bug and should be updated to `is_a?(Numeric)` or `is_a?(Float)`. Code that did `volume + 0.5` continues to work, but the result is now precise instead of truncating to integer-then-promoting.

### Added

- Regression-guard specs in `spec/lib/quant/ticks/ohlc_spec.rb` and `spec/lib/quant/ticks/spot_spec.rb` that explicitly assert `Float` class membership and use fractional values (`0.12345`, `5_678.901_234`) so a future `.to_i` regression would fail loudly rather than silently coerce.
- This CHANGELOG.

---

## [0.4.0] — prior baseline

Prior baseline before this CHANGELOG was introduced. Subsequent entries above will track changes from 0.4.1 forward.

[0.5.0]: https://github.com/mwlang/quantitative/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/mwlang/quantitative/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/mwlang/quantitative/releases/tag/v0.4.0
