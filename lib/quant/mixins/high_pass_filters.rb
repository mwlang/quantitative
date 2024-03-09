# frozen_string_literal: true

module Quant
  module Mixins
    # The following are high pass filters that are used to remove low frequency
    # components from a time series. In simple terms, a high pass filter
    # allows signals above a certain frequency (the cutoff frequency) to
    # pass through relatively unaffected, while attenuating or blocking
    # signals below that frequency.
    #
    # HighPass Filters are “detrenders” because they attenuate low frequency components
    # One pole HighPass and SuperSmoother does not produce a zero mean because low
    # frequency spectral dilation components are "leaking" through The one pole
    # HighPass Filter response
    #
    # == Experimental
    # Across the various texts and papers, Ehlers presents varying implementations
    # of high-pass filters.  I believe the two pole high-pass filter is the most
    # consistently presented while the one pole high-pass filter has been presented
    # in a few different ways.  In some implementations, alpha is based on simple
    # bars/lag while others use alpha based on phase/trigonometry.  I have not been
    # able to reconcile the differences and have not been able to find a definitive
    # source for the correct implementation and do not know enough math to reason
    # these out mathematically nor do I possess an advanced understanding of the
    # fundamentals around digital signal processing.  As such, the single-pole
    # high-pass filters in this module are marked as experimental and may be incorrect.
    module HighPassFilters
      # A two-pole high-pass filter is a more advanced filtering technique
      # used to remove low-frequency components from financial time series
      # data, such as stock prices or market indices.
      #
      # Similar to a single-pole high-pass filter, a two-pole high-pass filter
      # is designed to attenuate or eliminate slow-moving trends or macroeconomic
      # effects from the data while preserving higher-frequency fluctuations.
      # However, compared to the single-pole filter, the two-pole filter
      # typically offers a steeper roll-off and better attenuation of lower
      # frequencies, resulting in a more pronounced emphasis on short-term fluctuations.
      def two_pole_high_pass_filter(source, period:, previous: :hp)
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, "previous must be a Symbol" unless previous.is_a?(Symbol)

        alpha = period_to_alpha(period, k: 0.707)

        v1 = p0.send(source) - (2.0 * p1.send(source)) + p2.send(source)
        v2 = p1.send(previous)
        v3 = p2.send(previous)

        a = v1 * (1 - (alpha * 0.5))**2
        b = v2 * 2 * (1 - alpha)
        c = v3 * (1 - alpha)**2

        a + b - c
      end

      # A single-pole high-pass filter is used to filter out low-frequency
      # components from financial time series data. This type of filter is
      # commonly applied in signal processing techniques to remove noise or
      # unwanted trends from the data while preserving higher-frequency fluctuations.
      #
      # A single-pole high-pass filter can be used to remove slow-moving trends
      # or macroeconomic effects from the data, focusing instead on short-term
      # fluctuations or high-frequency trading signals. By filtering out
      # low-frequency components, traders aim to identify and exploit more
      # immediate market opportunities, such as short-term price movements
      # or momentum signals.
      #
      # The implementation of a single-pole high-pass filter in algorithmic
      # trading typically involves applying a mathematical formula or algorithm
      # to the historical price data of a financial instrument. This algorithm
      # selectively attenuates or removes the low-frequency components of the
      # data, leaving behind the higher-frequency fluctuations that traders
      # are interested in analyzing for potential trading signals.
      #
      # Overall, single-pole high-pass filters in algorithmic trading are
      # used as preprocessing steps to enhance the signal-to-noise ratio in
      # financial data and to extract actionable trading signals from noisy
      # or cluttered market data.
      #
      # == NOTES
      # alpha = (Cosine(.707* 2 * PI / 48) + Sine (.707*360 / 48) - 1) / Cosine(.707*360 / 48);
      # is the same as the following:
      # radians = Math.sqrt(2) * Math::PI / period
      # alpha = (Math.cos(radians) + Math.sin(radians) - 1) / Math.cos(radians)
      def high_pass_filter(source, period:, previous: :hp)
        Quant.experimental("This method is unproven and may be incorrect.")
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, "previous must be a Symbol" unless previous.is_a?(Symbol)

        radians = Math.sqrt(2) * Math::PI / period
        a = Math.exp(-radians)
        b = 2 * a * Math.cos(radians)

        c2 = b
        c3 = -a**2
        c1 = (1 + c2 - c3) / 4

        v0 = p0.send(source)
        v1 = p1.send(source)
        v2 = p2.send(source)
        f1 = p1.send(previous)
        f2 = p2.send(previous)

        (c1 * (v0 - (2 * v1) + v2)) + (c2 * f1) + (c3 * f2)
      end

      # HPF = (1 − α/2)2 * (Price − 2 * Price[1] + Price[2]) + 2 * (1 − α) * HPF[1] − (1 − α)2 * HPF[2];
      # High Pass Filter presented in Ehlers Cybernetic Analysis for Stocks and Futures Equation 2.7
      def hpf2(source, period:, previous:)
        Quant.experimental("This method is unproven and may be incorrect.")
        raise ArgumentError, "source must be a Symbol" unless source.is_a?(Symbol)
        raise ArgumentError, "previous must be a Symbol" unless previous.is_a?(Symbol)

        alpha = period_to_alpha(period, k: 1.0)
        v0 = p0.send(source)
        v1 = p1.send(source)
        v2 = p1.send(source)

        f1 = p1.send(previous)
        f2 = p2.send(previous)

        c1 = (1 - alpha / 2)**2
        c2 = 2 * (1 - alpha)
        c3 = (1 - alpha)**2

        (c1 * (v0 - (2 * v1) + v2)) + (c2 * f1) - (c3 * f2)
      end
    end
  end
end
