module Quant
  module Refinements
    # Refinements for the standard Ruby +Array+ class.
    # These refinements add statistical methods to the Array class as well as some optimizations that greatly
    # speed up some of the computations performed by the various indicators.
    #
    # In addtion to the statistical methods, the refinements also add a +max_size!+ method to the Array class, which
    # allows us to bound the array to a maximum number of elements, which is useful for indicators that are computing
    # averages or sums over a fixed number of lookback ticks.
    #
    # There are some various performance benchmarks in the spec/performance directory that show the performance
    # improvements of using these refinements.
    #
    # Keep in mind that within this library, we're generally concerned with adding to the tail of the arrays and
    # rarely with removing or popping, so there's few optimizations or protections for those operations in
    # conjunction with the +max_size+ setting.  The +max_size+ has also been designed to be set only once, to avoid
    # adding additional complexity to the code that is unnecessary until a use-case presents itself.
    #
    # Usage: Call +using Quant+ in the file or scope where you want to use these refinements.  It does not matter
    # if the arrays were instantiated outside the scope of the refinement, the refinements will still be applied.
    #
    # @example
    #   using Quant
    #
    #   array = [1, 2, 3, 4, 5]
    #   array.mean => 3.0
    #   another_array.max_size!(3).push(1, 2, 3, 4, 5, 6) => [4, 5, 6]
    #
    # @note The behavior of out of bound indexes into the Array deviates from standard Ruby and always returns an element.
    #   If an array only has three elements and 4 or more are requested for +n+, the method constrains itself to
    #   the size of the array. This is an intentional design decision, but it may be a gotcha if you're not expecting it.
    #   The refined behavior generally only exists within the library's scope, but if you call `using Quant` in your
    #   own code, you may encounter the changed behavior unexpectedly.
    module Array

      # Overrides the standard +<<+ method to track the +maximum+ and +minimum+ values
      # while also respecting the +max_size+ setting.
      def <<(value)
        push(value)
      end

      # Overrides the standard +push+ method to track the +maximum+ and +minimum+ values
      # while also respecting the +max_size+ setting.
      def push(*objects)
        Array(objects).each do |object|
          super(object)
          if @max_size && size > @max_size
            voted_off = shift
            @minimum = min if voted_off == @minimum
            @maximum = max if voted_off == @maximum
          else
            @maximum = object if @maximum.nil? || object > @maximum
            @minimum = object if @minimum.nil? || object < @minimum
          end
        end
        self
      end

      # Returns the maximum element value in the array.  It is an optimized version of the standard +max+ method.
      def maximum
        @maximum || max
      end

      # Returns the minimum element value in the array.  It is an optimized version of the standard +min+ method.
      def minimum
        @minimum || min
      end

      # Treats the tail of the array as starting at zero and counting up.  Does not overflow the head of the array.
      # That is, if the +Array+ has 5 elements, prev(10) would return the first element in the array.
      #
      # @example
      #   series = [1, 2, 3, 4]
      #   series.prev(0) # => series[-1] => series[3] => 4
      #   series.prev(1) # => series[-2] => series[3] => 3
      #   series.prev(2) # => series[-3] => series[2] => 2
      #   series.prev(3) # => series[-4] => series[1] => 1
      #   series.prev(4) # => series[-4] => series[0] => 1 (no out of bounds!)
      #
      # Useful for when translating TradingView or MQ4 indicators to Ruby where those programs' indexing starts at 0
      # for most recent bar and counts up to the oldest bar.
      def prev(index)
        raise ArgumentError, "index must be positive" if index < 0

        self[[size - (index + 1), 0].max]
      end

      # Sets the maximum size of the array.  When the size of the array exceeds the
      # +max_size+, the first element is removed from the array.
      # This setting modifies :<< and :push methods.
      def max_size!(max_size)
        # These guards are maybe not necessary, but they are here until a use-case is found.
        # My concern lies with indicators that are built specifically against the +max_size+ of a given array.
        raise Quant::ArrayMaxSizeError, 'cannot set max_size to nil.' unless max_size
        raise Quant::ArrayMaxSizeError, 'can only max_size! once.' if @max_size
        raise Quant::ArrayMaxSizeError, "size of Array #{size} exceeds max_size #{max_size}." if size > max_size

        @max_size = max_size
        self
      end

      # Computes the mean of the array.  When +n+ is specified, the mean is computed over
      # the last +n+ elements, otherwise it is computed over the entire array.
      #
      # @param n [Integer] the number of elements to compute the mean over
      # @return [Float]
      def mean(n: size)
        subset = last(n)
        return 0.0 if subset.empty?

        sum = subset.sum / subset.size.to_f
      end

      # Computes the Exponential Moving Average (EMA) of the array.  When +n+ is specified,
      # the EMA is computed over the last +n+ elements, otherwise it is computed over the entire array.
      # An Array of EMA's is returned, with the first entry always the first value in the subset.
      #
      # @params n [Integer] the number of elements to compute the EMA over.
      # @return [Array<Float>]
      def ema(n: size)
        subset = last(n)
        return [] if subset.empty?

        alpha = 2.0 / (subset.size + 1)
        naught_alpha = (1.0 - alpha)
        pvalue = subset[0]
        subset.map do |value|
          pvalue = (alpha * value) + (naught_alpha * pvalue)
        end
      end

      # Computes the Simple Moving Average (SMA) of the array.  When +n+ is specified,
      # the SMA is computed over the last +n+ elements, otherwise it is computed over the entire array.
      # An Array of SMA's is returned, with the first entry always the first value in the subset.
      #
      # @param n [Integer] the number of elements to compute the SMA over
      # @return [Array<Float>]
      def sma(n: size)
        subset = last(n)
        return [] if subset.empty?

        pvalue = subset[0]
        subset.map do |value|
          pvalue = (pvalue + value) / 2.0
        end
      end

      # Computes the Weighted Moving Average (WMA) of the array.  When +n+ is specified,
      # the WMA is computed over the last +n+ elements, otherwise it is computed over the entire array.
      # An Array of WMA's is returned, with the first entry always the first value in the subset.
      #
      # @param n [Integer] the number of elements to compute the WMA over
      # @return [Array<Float>]
      def wma(n: size)
        subset = last(n)
        return [] if subset.empty?

        # ensures we return not more than number of elements in full array,
        # yet have enough values to compute each iteration
        max_size = [size, n].min
        while subset.size <= max_size + 2
          subset.unshift(subset[0])
        end

        subset.each_cons(4).map do |v1, v2, v3, v4|
          (4.0 * v4 + 3.0 * v3 + 2.0 * v2 + v1) / 10.0
        end
      end

      # Computes the Standard Deviation of the array.  When +n+ is specified,
      # the Standard Deviation is computed over the last +n+ elements,
      # otherwise it is computed over the entire array.
      #
      # @param n [Integer] the number of elements to compute the Standard Deviation over.
      # @return [Float]
      def stddev(reference_value, n: size)
        variance(reference_value, n: n) ** 0.5
      end

      def variance(reference_value, n: size)
        subset = last(n)
        return 0.0 if subset.empty?

        subset.empty? ? 0.0 : subset.map{ |v| (v - reference_value)**2 }.mean
      end
    end
  end

  refine Array do
    import_methods Quant::Refinements::Array

    alias std_dev stddev
    alias standard_deviation stddev
    alias var variance
  end
end
