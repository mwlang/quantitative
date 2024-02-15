# frozen_string_literal: true

module Quant
  # Stocks (Equities): Represent ownership in a company. Stockholders are entitled to a share
  # of the company's profits and have voting rights at shareholder meetings.

  # Bonds (Fixed-Income Securities): Debt instruments where an investor lends money to an entity
  # (government or corporation) in exchange for periodic interest payments and the return of
  #  the principal amount at maturity.

  # Mutual Funds: Pooled funds managed by an investment company. Investors buy shares in the mutual
  # fund, and the fund invests in a diversified portfolio of stocks, bonds, or other securities.

  # Exchange-Traded Funds (ETFs): Similar to mutual funds but traded on stock exchanges.
  # ETFs can track an index, commodity, bonds, or a basket of assets.

  # Options: Derivative securities that give the holder the right (but not the obligation) to buy
  # or sell an underlying asset at a predetermined price before or at expiration.

  # Futures: Contracts that obligate the buyer to purchase or the seller to sell an
  # asset at a predetermined future date and price.

  # Real Estate Investment Trusts (REITs): Companies that own, operate, or finance income-generating
  # real estate. Investors can buy shares in a REIT, which provides them with a share of the
  # income produced by the real estate.

  # Cryptocurrencies: Digital or virtual currencies that use cryptography for security and operate on
  # decentralized networks, typically based on blockchain technology. Examples include Bitcoin, Ethereum, and Ripple.

  # Preferred Stock: A type of stock that has priority over common stock in terms of dividend
  # payments and asset distribution in the event of liquidation.

  # Treasury Securities: Issued by the government to raise funds. Types include Treasury bills (T-bills),
  # Treasury notes (T-notes), and Treasury bonds (T-bonds).

  # Mortgage-Backed Securities (MBS): Securities that represent an ownership interest in a pool of mortgage loans.
  # Investors receive payments based on the interest and principal of the underlying loans.

  # Commodities: Physical goods such as gold, silver, oil, or agricultural products, traded on commodity exchanges.

  # Foreign Exchange (Forex): The market where currencies are traded. Investors can buy and sell currencies to
  # profit from changes in exchange rates.
  class SecurityClass
    CLASSES = %i(
      bond
      commodity
      cryptocurrency
      etf
      forex
      future
      mbs
      mutual_fund
      option
      preferred_stock
      reit
      stock
      treasury_note
    ).freeze

    attr_reader :security_class

    def initialize(name)
      return if @security_class = from_standard(name)

      @security_class = from_alternate(name.to_s.downcase.to_sym) unless name.nil?
      raise_unknown_security_class_error(name) unless security_class
    end

    CLASSES.each do |class_name|
      define_method("#{class_name}?") do
        security_class == class_name
      end
    end

    def raise_unknown_security_class_error(name)
      raise SecurityClassError, "Unknown security class: #{name.inspect}"
    end

    def to_s
      security_class.to_s
    end

    def to_h
      { "sc" => security_class }
    end

    def to_json(*args)
      Oj.dump(to_h, *args)
    end

    def ==(other)
      case other
      when String then from_alternate(other.to_sym) == security_class
      when Symbol then from_alternate(other) == security_class
      when SecurityClass then other.security_class == security_class
      else
        false
      end
    end

    private

    ALTERNATE_NAMES = {
      us_equity: :stock,
      crypto: :cryptocurrency,
    }.freeze

    def from_standard(name)
      name if CLASSES.include?(name)
    end

    def from_alternate(alt_name)
      from_standard(alt_name) || ALTERNATE_NAMES[alt_name]
    end
  end
end
