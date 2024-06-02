# frozen_string_literal: true

RSpec.describe Quant::Indicators::IndicatorPoint do
  subject { described_class.new(indicator:, tick:, source:) }

  describe "attributes" do
    let(:indicator) { instance_double(Quant::Indicators::Indicator, min_period: 1) }
    let(:tick) { instance_double(Quant::Ticks::OHLC, oc2: 3.0, low_price: 1.0, high_price: 8.0, open_price: 2.0, volume: 100) }
    let(:source) { :oc2 }

    it { expect(subject.tick).to eq(tick) }
    it { expect(subject.source).to eq(source) }
    it { expect(subject.input).to eq(3.0) }
    it { expect(subject.to_h).to eq("in" => 3.0, "src" => :oc2) }
    it { expect(subject.min_period).to eq(1) }
    it { expect(subject.high_price).to eq(8.0) }
    it { expect(subject.low_price).to eq(1.0) }
    it { expect(subject.oc2).to eq(3.0) }
    it { expect(subject.volume).to eq(100) }
  end
end
