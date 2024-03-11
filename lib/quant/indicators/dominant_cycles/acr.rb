require_relative "../indicator_point"
require_relative "dominant_cycle"

module Quant
  class Indicators
    class DominantCycles
      class AcrPoint < DominantCyclePoint
        attribute :hp, default: 0.0
        attribute :filter, default: 0.0
        attribute :interim_period, default: 0.0
        attribute :inst_period, default: :min_period
        attribute :period, default: 0.0
        attribute :sp, default: 0.0
        attribute :spx, default: 0.0
        attribute :maxpwr, default: 0.0
        attribute :r1, default: -> { Hash.new(0.0) }
        attribute :corr, default: -> { Hash.new(0.0) }
        attribute :pwr, default: -> { Hash.new(0.0) }
        attribute :cospart, default: -> { Hash.new(0.0) }
        attribute :sinpart, default: -> { Hash.new(0.0) }
        attribute :sqsum, default: -> { Hash.new(0.0) }
        attribute :reversal, default: false
      end

      # Auto-Correlation Reversals
      class Acr < DominantCycle
        def average_length
          3 # AvgLength
        end

        def bandwidth
          deg2rad(370)
        end

        def compute_auto_correlations
          (min_period..max_period).each do |period|
            corr = Statistics::Correlation.new
            average_length.times do |lookback_period|
              corr.add(p(lookback_period).filter, p(period + lookback_period).filter)
            end
            p0.corr[period] = corr.coefficient
          end
        end

        def compute_powers
          p0.maxpwr = 0.995 * p1.maxpwr

          (min_period..max_period).each do |period|
            (average_length..max_period).each do |n|
              radians = bandwidth * n / period
              p0.cospart[period] += p0.corr[n] * Math.cos(radians)
              p0.sinpart[period] += p0.corr[n] * Math.sin(radians)
            end
            p0.sqsum[period] = p0.cospart[period]**2 + p0.sinpart[period]**2
            p0.r1[period] = (0.2 * p0.sqsum[period]**2) + (0.8 * p1.r1[period])
            p0.pwr[period] = p0.r1[period]
            p0.maxpwr = [p0.maxpwr, p0.r1[period]].max
          end
          return if p0.maxpwr.zero?

          (min_period..max_period).each do |period|
            p0.pwr[period] = p0.r1[period] / p0.maxpwr
          end
        end

        def compute_period
          (min_period..max_period).each do |period|
            if p0.pwr[period] >= 0.4
              p0.spx += (period * p0.pwr[period])
              p0.sp += p0.pwr[period]
            end
          end

          p0.interim_period = p0.sp.zero? ? p1.period : p0.spx / p0.sp
          p0.inst_period = two_pole_butterworth(:interim_period, previous: :period, period: min_period)
          p0.period = p0.inst_period.round(0)
        end

        def compute_reversal
          sum_deltas = 0
          (min_period..max_period).each do |period|
            sc1 = (p0.corr[period] + 1) * 0.5
            sc2 = (p1.corr[period] + 1) * 0.5
            sum_deltas += 1 if (sc1 > 0.5 && sc2 < 0.5) || (sc1 < 0.5 && sc2 > 0.5)
          end
          p0.reversal = sum_deltas > 24
        end

        def compute
          p0.hp = two_pole_high_pass_filter(:input, period: max_period)
          p0.filter = two_pole_butterworth(:hp, previous: :filter, period: min_period)

          compute_auto_correlations
          compute_powers
          compute_period
          compute_reversal
        end
      end
    end
  end
end