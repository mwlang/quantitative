module SeriesFactory
  def sine_series(period:, cycles:)
    Quant::Series.new(symbol: "SINE", interval: "1d").tap do |series|
      cycles.times do
        (0...period).each do |degree|
          radians = degree * 2 * Math::PI / period
          series << 5.0 * Math.sin(radians) + 10.0
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include SeriesFactory
end