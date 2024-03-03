# frozen_string_literal: true

module Quant
  module Mixins
    # Source: Ehlers, J. F. (2013). Cycle Analytics for Traders:
    #         Advanced Technical Trading Concepts. John Wiley & Sons.
    #
    # == Universal Filters
    # Ehlers devoted a chapter in his book to generalizing the algorithms
    # for the most common filters used in trading. The universal filters
    # makes an attempt to translate that work into working code.  However,
    # Ehler write up contained some typos and incomplete treatment of the
    # subject matter, and as a non-mathematician, I am not sure if I have
    # translated the formulas correctly.  So far, I have not been able to
    # prove correctness of the universal EMA vs. the optimzed EMA, but
    # the others are still unproven and Ehlers' many papers over the year
    # tend to change implementation details, too.
    #
    # == Ehlers' Notes on Generalized Filters
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
    #   Filter Type           b0          b1              b2          a1        a2
    #   EMA                   α           0               0           −(1−α)    0
    #   Two-pole low-pass     α**2        0               0           −2*(1-α)  (1-α)**2
    #   High-pass             (1-α/2)     -(1-α/2)        0           −(1−α)    0
    #   Two-pole high-pass    (1-α/2)**2  -2*(1-α/2)**2   (1-α/2)**2  -2*(1-α)  (1-α)**2
    #   Band-pass             (1-σ)/2     0               -(1-σ)/2    -λ*(1+σ)  σ
    #   Band-stop             (1+σ)/2     -2λ*(1+σ)/2     (1+σ)/2     -λ*(1+σ)  σ
    #
    module UniversalFilters
      K = {
        single_pole: 1.0,
        two_pole_high_pass: Math.sqrt(2) * 0.5,
        two_pole_low_pass: Math.sqrt(2)
      }.freeze

      # The universal filter is a generalization of the common filters.  The other
      # algorithms in this module are derived from this one.
      def universal_filter(source, previous:, b0:, b1:, b2:, a1:, a2:)
        b0 * p0.send(source) +
          b1 * p1.send(source) +
          b2 * p2.send(source) -
          a1 * p1.send(previous) -
          a2 * p2.send(previous)
      end

      # The EMA is optimized in the {Quant::Mixins::ExponentialMovingAverage} module
      # and its correctness is proven with this particular implementation.
      def universal_ema(source, previous:, period:)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, ":previous must be a Symbol" unless previous.is_a?(Symbol)

        alpha = bars_to_alpha(period)
        b0 = alpha
        b1 = 0
        b2 = 0
        a1 = -(1 - alpha)
        a2 = 0

        universal_filter(source, previous:, b0:, b1:, b2:, a1:, a2:)
      end

      # The two-pole low-pass filter can serve several purposes:
      #
      # 1. Noise Reduction: Stock price data often contains high-frequency
      #    fluctuations or noise due to market volatility, algorithmic
      #    trading, or other factors. By applying a low-pass filter, you can
      #    smooth out these fluctuations, making it easier to identify
      #    underlying trends or patterns in the price action.
      # 2. Trend Identification: Low-pass filtering can help in identifying
      #    the underlying trend in stock price movements by removing short-term
      #    fluctuations and emphasizing longer-term movements. This can be
      #    useful for trend-following strategies or identifying potential
      #    trend reversals.
      # 3. Signal Smoothing: Filtering can help in removing erratic or
      #    spurious movements in the price data, providing a clearer and
      #    more consistent representation of the overall price action.
      # 4. Highlighting Structural Changes: Filtering can make structural
      #    changes in the price action more apparent by reducing noise and
      #    focusing on significant movements. This can be useful for detecting
      #    shifts in market sentiment or the emergence of new trends.
      # 5. Trade Signal Generation: Smoothed price data from a low-pass filter
      #    can be used as input for trading strategies, such as moving
      #    average-based strategies or momentum strategies, where identifying
      #    trends or momentum is crucial.
      def universal_two_pole_low_pass(source, previous:, period:)
        Quant.experimental("This method is unproven and may be incorrect.")
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, ":previous must be a Symbol" unless previous.is_a?(Symbol)

        alpha = period_to_alpha(period, k: K[:two_pole_low_pass] )
        b0 = alpha**2
        b1 = 0
        b2 = 0
        a1 = -2.0 * (1.0 - alpha)
        a2 = (1.0 - alpha)**2

        universal_filter(source, previous:, b0:, b1:, b2:, a1:, a2:)
      end

      # A single-pole low-pass filter, also known as a first-order low-pass
      # filter, has a simpler response compared to a two-pole low-pass filter.
      # It attenuates higher-frequency components of the signal while allowing
      # lower-frequency components to pass through, but it does so with a
      # gentler roll-off compared to higher-order filters.
      #
      # Here's what a single-pole low-pass filter typically does to stock
      # price action data:
      # 1. Noise Reduction: Similar to a two-pole low-pass filter, a single-pole
      #    filter can help in reducing high-frequency noise in stock price data,
      #    smoothing out rapid fluctuations caused by market volatility or other factors.
      # 2. Trend Identification: It can aid in identifying trends by smoothing
      #    out short-term fluctuations, making the underlying trend more apparent.
      #    However, compared to higher-order filters, it may not provide as
      #    sharp or accurate trend signals.
      # 3. Signal Smoothing: Single-pole filters provide a basic level of signal
      #    smoothing, which can help in removing minor fluctuations and emphasizing
      #    larger movements in the price action. This can make the data easier to
      #    interpret and analyze.
      # 4. Delay and Responsiveness: Single-pole filters introduce less delay
      #    compared to higher-order filters, making them more responsive to changes
      #    in the input signal. However, this responsiveness comes at the cost of a
      #    less aggressive attenuation of high-frequency noise.
      # 5. Simple Filtering: Single-pole filters are computationally efficient and
      #    easy to implement, making them suitable for real-time processing and
      #    applications where simplicity is preferred.
      #
      # Overall, while a single-pole low-pass filter can still be effective for
      # noise reduction and basic trend identification in stock price action data,
      # it may not offer the same level of precision and robustness as higher-order
      # filters. The choice between single-pole and higher-order filters depends on
      # the specific requirements of the analysis and the trade-offs between
      # responsiveness and noise attenuation.
      def universal_one_pole_low_pass(source, previous:, period:)
        Quant.experimental("This method is unproven and may be incorrect.")
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, ":previous must be a Symbol" unless previous.is_a?(Symbol)

        alpha = period_to_alpha(period, k: K[:single_pole])
        b0 = alpha
        b1 = 0
        b2 = 0
        a1 = -(1 - alpha)
        a2 = 0

        universal_filter(source, previous:, b0:, b1:, b2:, a1:, a2:)
      end

      # A single-pole high-pass filter, also known as a first-order high-pass
      # filter, attenuates low-frequency components of a signal while allowing
      # higher-frequency components to pass through. In the context of processing
      # stock price action data, applying a single-pole high-pass filter has
      # several potential effects:
      #
      # 1. Removal of Low-Frequency Trends: Similar to higher-order high-pass
      #    filters, a single-pole high-pass filter removes or attenuates slow-moving
      #    components of the price action data, such as long-term trends. This can
      #    help in focusing on shorter-term fluctuations and identifying short-term
      #    trading opportunities.
      # 2. Noise Amplification: As with higher-order high-pass filters, a single-pole
      #    high-pass filter can amplify high-frequency noise present in the data,
      #    especially if the cutoff frequency is set too low. This noise amplification
      #    can make it challenging to analyze the data accurately, particularly if the
      #    noise overwhelms the signal of interest.
      # 3. Emphasis on Short-Term Variations: By removing low-frequency components, a
      #    single-pole high-pass filter highlights short-term variations and rapid
      #    movements in the price action data. This can be beneficial for traders or
      #    analysts who are primarily interested in short-term price dynamics or
      #    intraday trading opportunities.
      # 4. Simple Filtering: Single-pole filters are computationally efficient and
      #    straightforward to implement, making them suitable for real-time processing
      #    and applications where simplicity is preferred. However, they may not offer
      #    the same level of noise attenuation and signal preservation as higher-order
      #    filters.
      # 5. Enhanced Responsiveness: Single-pole high-pass filters offer relatively high
      #    responsiveness to changes in the input signal, reflecting recent price movements
      #    quickly. This responsiveness can be advantageous for certain trading strategies
      #    that rely on timely identification of market events or short-term trends.
      #
      # Overall, applying a single-pole high-pass filter to stock price action data can
      # help in removing low-frequency trends and focusing on short-term variations and
      # rapid movements. However, it's essential to carefully select the cutoff frequency
      # to balance noise attenuation with signal preservation and to consider the potential
      # trade-offs between simplicity and filtering effectiveness.
      def universal_one_pole_high_pass(source, previous:, period:)
        Quant.experimental("This method is unproven and may be incorrect.")
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, ":previous must be a Symbol" unless previous.is_a?(Symbol)

        alpha = period_to_alpha(period, k: K[:single_pole])
        b0 = (1 - alpha / 2)
        b1 = -(1 - alpha / 2)
        b2 = 0
        a1 = -(1 - alpha)
        a2 = 0

        universal_filter(source, previous:, b0:, b1:, b2:, a1:, a2:)
      end

      # A two-pole high-pass filter, also known as a second-order high-pass
      # filter, attenuates low-frequency components of a signal while allowing
      # higher-frequency components to pass through. In the context of
      # processing stock price action data, applying a two-pole high-pass
      # filter has several potential effects:
      #
      # 1. Removal of Low-Frequency Trends: High-pass filtering can remove
      #    or attenuate long-term trends or slow-moving components of the
      #    price action data. This can be useful for focusing on shorter-term
      #    fluctuations or identifying short-term trading opportunities.
      # 2. Noise Attenuation: By suppressing low-frequency components, a
      #    high-pass filter can help in reducing the impact of slow-moving
      #    noise or irrelevant signals in the data. This can improve the
      #    clarity and interpretability of the price action data.
      # 3. Noise Amplification: High-pass filters can amplify high-frequency
      #    noise present in the data, particularly if the cutoff frequency is
      #    set too low. This noise amplification can make it challenging to
      #    analyze the data accurately, especially if the noise overwhelms
      #    the signal of interest.
      # 4. Emphasis on Short-Term Variations: By removing low-frequency
      #    components, a high-pass filter highlights short-term variations
      #    and rapid movements in the price action data. This can be beneficial
      #    for traders or analysts who are primarily interested in short-term
      #    price dynamics.
      # 5. Enhanced Responsiveness: Compared to low-pass filters, high-pass
      #    filters typically offer greater responsiveness to changes in the
      #    input signal. This means that high-pass filtered data can reflect
      #    recent price movements more quickly, which may be advantageous for
      #    certain trading strategies.
      # 6. Identification of Market Events: High-pass filtering can help in
      #    identifying specific market events or anomalies that occur on
      #    shorter time scales, such as intraday price spikes or volatility
      #    clusters.
      #
      # Overall, applying a two-pole high-pass filter to stock price action
      # data can help in focusing on short-term variations and removing
      # long-term trends or slow-moving components. However, it's essential
      # to carefully select the cutoff frequency to balance noise attenuation
      # with signal preservation, as excessive noise amplification can degrade
      # the quality of the analysis. Additionally, high-pass filtering may
      # not be suitable for all trading or analysis purposes, and its effects
      # should be evaluated in the context of specific goals and strategies.
      def universal_two_pole_high_pass(source, previous:, period:)
        Quant.experimental("This method is unproven and may be incorrect.")
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, ":previous must be a Symbol" unless previous.is_a?(Symbol)

        alpha = period_to_alpha(period, k: K[:two_pole_high_pass])
        b0 = (1 - alpha / 2)**2
        b1 = -2 * (1 - alpha / 2)**2
        b2 = (1 - alpha / 2)**2
        a1 = -2 * (1 - alpha)
        a2 = (1 - alpha)**2

        universal_filter(source, previous:, b0:, b1:, b2:, a1:, a2:)
      end

      # Band-pass filters are both detrenders and smoothers because they
      # attenuate all but the desired frequency components.
      # NOTE: Ehlers' book contains a typo in the formula for the band-pass
      # filter.  I am not sure what the correct formulation is, so
      # this is a best guess for how, left for further investigation.
      def universal_band_pass(source, previous:, period:)
        Quant.experimental("This method is unproven and may be incorrect.")
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, ":previous must be a Symbol" unless previous.is_a?(Symbol)

        lambda = deg2rad(360.0 / period)
        gamma = Math.cos(lambda)
        sigma = 1 / gamma - Math.sqrt(1 / gamma**2 - 1)

        b0 = (1 - sigma) * 0.5
        b1 = 0
        b2 = -(1 - sigma) * 0.5
        a1 = -lambda * (1 + sigma)
        a2 = sigma

        universal_filter(source, previous:, b0:, b1:, b2:, a1:, a2:)
      end
    end
  end
end
