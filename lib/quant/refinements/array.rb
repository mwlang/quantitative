module Quant
  module Refinements
    module Array
      # Computes the mean of the array.  When +n+ is specified, the mean is computed over
      # the last +n+ elements.
      #
      # @param n [Integer] the number of elements to compute the mean over
      # @return [Float]
      def mean(n: size)
        subset = period(n: n)
        return 0.0 if subset.empty?

        sum = subset.sum / subset.size.to_f
      end

      # Returns the last +n+ elements (tail) of the array or the entire array if +n+ is greater
      # than the size of the array.
      #
      # @param n [Integer] the number of elements to return
      # @return [Array]
      def period(n: size)
        return self if n >= size

        n = [n, size].min
        n.zero? ? [] : slice(-n, n)
      end

      # Computes the Exponential Moving Average (EMA) of the array.  When +n+ is specified,
      # the EMA is computed over the last +n+ elements.
      # An Array of EMA's is returned, with the first entry always the first value in the subset.
      #
      # @params n [Integer] the number of elements to compute the EMA over.
      # @return [Array<Float>]
      def ema(n: size)
        subset = period(n: n)
        return [] if subset.empty?

        alpha = 2.0 / (subset.size + 1)
        naught_alpha = (1.0 - alpha)
        pvalue = subset[0]
        subset.map do |value|
          pvalue = (alpha * value) + (naught_alpha * pvalue)
        end
      end

      # Computes the Simple Moving Average (SMA) of the array.  When +n+ is specified,
      # the SMA is computed over the last +n+ elements.
      # An Array of SMA's is returned, with the first entry always the first value in the subset.
      #
      # @param n [Integer] the number of elements to compute the SMA over
      # @return [Array<Float>]
      def sma(n: size)
        subset = period(n: n)
        return [] if subset.empty?

        pvalue = subset[0]
        subset.map do |value|
          pvalue = (pvalue + value) / 2.0
        end
      end

      # Computes the Weighted Moving Average (WMA) of the array.  When +n+ is specified,
      # the WMA is computed over the last +n+ elements.
      # An Array of WMA's is returned, with the first entry always the first value in the subset.
      #
      # @param n [Integer] the number of elements to compute the WMA over
      # @return [Array<Float>]
      def wma(n: size)
        subset = period(n: n)
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
      # the Standard Deviation is computed over the last +n+ elements.
      #
      # @param n [Integer] the number of elements to compute the Standard Deviation over.
      # @return [Float]
      def stddev(reference_value, n: size)
        variance(reference_value, n: n) ** 0.5
      end

      def variance(reference_value, n: size)
        subset = period(n: n)
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
