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

      value.is_a?(Date) ? beginning_of_day(value) : value.to_time
    end

    def as_end_time(value)
      return value if value.nil? || value.is_a?(Time)

      value.is_a?(Date) ? end_of_day(value) : value.to_time
    end

    def end_of_day(date)
      Time.utc(date.year, date.month, date.day, 23, 59, 59)
    end

    def beginning_of_day(date)
      Time.utc(date.year, date.month, date.day)
    end

    def validate_bounds!
      return if lower_bound? || upper_bound?

      raise "TimePeriod cannot be unbound at start_at and end_at"
    end

    def cover?(value)
      (start_at..end_at).cover?(value)
    end

    def start_at
      (@start_at || LOWER_BOUND).round
    end

    def lower_bound?
      !lower_unbound?
    end

    def lower_unbound?
      @start_at.nil?
    end

    def upper_unbound?
      @end_at.nil?
    end

    def upper_bound?
      !upper_unbound?
    end

    def end_at
      (@end_at || Time.now.utc).round
    end

    def duration
      end_at - start_at
    end

    def ==(other)
      return false unless other.is_a?(TimePeriod)

      [lower_bound?, upper_bound?, start_at, end_at] ==
        [other.lower_bound?, other.upper_bound?, other.start_at, other.end_at]
    end

    def to_h
      { start_at:, end_at: }
    end
  end
end
