# frozen_string_literal: true

module Quant
  module_function

  # The library is designed to work with UTC time.  This method provides a single point of
  # access for the current time.  This is useful for testing and for retrieving the current time in
  # one place for the entire library.
  def current_time
    Time.now.utc
  end

  # This method, similar to +current_time+, provides a single point of access for the current date.
  def current_date
    Date.today
  end

  module TimeMethods
    # Provides lower-bounds for dates and times.  See +Quant::TimePeriod+ for example use-case.
    EPOCH_DATE = Date.civil(1492, 10, 12).freeze # arbitrary! (blame #co-pilot)
    EPOCH_TIME = Time.new(EPOCH_DATE.year, EPOCH_DATE.month, EPOCH_DATE.day, 0, 0, 0, "+00:00").utc.freeze

    # The epoch date is a NULL object +Date+ for the library.  It is used to represent the
    # beginning of time. That is, a date that is without bound and helps avoid +nil+ checks,
    # +NULL+ database entries, and such when working with dates.
    def self.epoch_date
      EPOCH_DATE
    end

    # The epoch time is a NULL object +Time+ for the library.  It is used to represent the
    # beginning of time. That is, a time that is without bound and helps avoid +nil+ checks,
    # +NULL+ database entries, and such when working with time.
    def self.epoch_time
      EPOCH_TIME
    end

    # When streaming or extracting a time entry from a payload, Time can already be parsed into a +Time+ object.
    # Or it may be an +Integer+ representing the number of seconds since the epoch.  Or it may be a +String+ that
    # can be parsed into a +Time+ object.  This method normalizes the time into a +Time+ object on the UTC timezone.
    def extract_time(value)
      case value
      when Time
        value.utc
      when Integer
        Time.at(value).utc
      when String
        Time.parse(value).utc
      else
        raise ArgumentError, "Invalid time: #{value.inspect}"
      end
    end
  end
end
