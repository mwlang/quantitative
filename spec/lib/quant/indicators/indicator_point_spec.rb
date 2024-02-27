# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Indicators::IndicatorPoint do
  subject { described_class.new(tick:, source:) }

  describe "attributes" do
    let(:tick) { instance_double(Quant::Ticks::OHLC, oc2: 3.0, open_price: 2.0, volume: 100) }
    let(:source) { :oc2 }

    it { expect(subject.tick).to eq(tick) }
    it { expect(subject.source).to eq(source) }
    it { expect(subject.input).to eq(3.0) }
    it { expect(subject.to_h).to eq("in" => 3.0, "src" => :oc2) }
  end
end
