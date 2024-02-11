# frozen_string_literal: true

module Quant
  class TimePeriod
    LOWER_BOUND = TimeMethods::EPOCH_TIME

    def initialize(start_at: nil, end_at: nil, span: nil)
      @start_at = as_start_time(start_at)
      @end_at = as_end_time(end_at)
      validate_bounds!

      @start_at = @end_at - span if !lower_bound? && span
      @end_at = @start_at + span if !upper_bound? && span
    end

    def as_start_time(value)
      return value if value.nil? || value.is_a?(Time)

      value.is_a?(Date) ? value.to_time.beginning_of_day : value.to_time
    end

    def as_end_time(value)
      return value if value.nil? || value.is_a?(Time)

      value.is_a?(Date) ? value.to_time.end_of_day : value.to_time
    end

    def validate_bounds!
      return if lower_bound? || upper_bound?

      raise "TimePeriod cannot be unbounded at start_at and end_at"
    end

    def cover?(value)
      (start_at..end_at).cover?(value)
    end

    def start_at
      (@start_at || LOWER_BOUND).round
    end

    def lower_bound?
      !!@start_at
    end

    def upper_bound?
      !!@end_at
    end

    def end_at
      (@end_at || Time.now.utc).round
    end

    def duration
      end_at - start_at
    end

    def ==(other)
      return false unless other.is_a?(TimePeriod)

      if lower_bound?
        other.lower_bound? && start_at == other.start_at
      elsif upper_bound?
        oher.upper_bound? && end_at == other.end_at
      else
        [start_at, end_at] == [other.start_at, other.end_at]
      end
    end

    def eql?(other)
      self == other
    end

    def to_h
      { start_at: start_at, end_at: end_at }
    end
  end
end
