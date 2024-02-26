# frozen_string_literal: true

module Quant
  module Mixins
    # 1.  All the common filters useful for traders have a transfer response
    #     that can be written as a ratio of two polynomials.
    # 2.  Lag is very important to traders. More complex filters can be
    #     created using more input data, but more input data increases lag.
    #     Sophisticated filters are not very useful for trading because they
    #     incur too much lag.
    # 3.  Filter transfer response can be viewed in the time domain and
    #     the frequency domain with equal validity.
    # 4.  Nonrecursive filters can have zeros in the transfer response, enabling
    #     the complete cancellation of some selected frequency components.
    # 5.  Nonrecursive filters having coefficients symmetrical about the
    #     center of the filter will have a delay of half the degree of the
    #     transfer response polynomial at all frequencies.
    # 6.  Low-pass filters are smoothers because they attenuate the high-frequency
    #     components of the input data.
    # 7.  High-pass filters are detrenders because they attenuate the
    #     low-frequency components of trends.
    # 8.  Band-pass filters are both detrenders and smoothers because they
    #     attenuate all but the desired frequency components.
    # 9.  Filters provide an output only through their transfer response.
    #     The transfer response is strictly a mathematical function, and
    #     interpretations such as overbought, oversold, convergence, divergence,
    #     and so on are not implied. The validity of such interpretations
    #     must be made on the basis of statistics apart from the filter.
    # 10. The critical period of a filter output is the frequency at which
    #     the output power of the filter is half the power of the input
    #     wave at that frequency.
    # 11. A WMA has little or no redeeming virtue.
    # 12. A median filter is best used when the data contain impulsive noise
    #     or when there are wild variations in the data. Smoothing volume
    #     data is one example of a good application for a median filter.
    #
    # == Filter Coefficients forVariousTypes of Filters
    #
    #   Filter Type           b0          b1              b2          a0        a1        a2
    #   EMA                   α           0               0           1         −(1−α)    0
    #   Two-pole low-pass     α**2        0               0           1         −2*(1-α)  (1-α)**2
    #   High-pass             (1-α/2)     -(1-α/2)        0           1         −(1−α)    0
    #   Two-pole high-pass    (1-α/2)**2  -2*(1-α/2)**2   (1-α/2)**2  1         -2*(1-α)  (1-α)**2
    #   Band-pass             (1-σ)/2     0               -(1-σ)/2    1         -λ*(1+σ)  σ
    #   Band-stop             (1+σ)/2     -2λ*(1+σ)/2     (1+σ)/2     1         -λ*(1+σ)  σ
    #
    module Filters
      include Mixins::ButterworthFilters
    end
  end
end
