# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Ticks::Serializers::OHLC do
  let(:current_time) { Quant.current_time.round }
  let(:one_minute) { 60 }
  let(:open_time) { current_time }
  let(:close_time) { current_time + one_minute }
  let(:tick_class) { Quant::Ticks::OHLC }

  describe ".from" do
    let(:hash) do
      {
        "ot" => open_time.to_i,
        "ct" => close_time,
        "o" => 1.0,
        "h" => 2.0,
        "l" => 3.0,
        "c" => 4.0,
        "bv" => 2.0,
        "tv" => 3.0
      }
    end

    subject(:tick) { described_class.from(hash, tick_class: tick_class) }

    context "valid" do
      it { is_expected.to be_a(tick_class) }

      it "has the correct attributes" do
        expect(tick.close_timestamp).to eq(close_time)
        expect(tick.open_timestamp).to eq(open_time)

        expect(tick.open_price).to eq(1.0)
        expect(tick.high_price).to eq(2.0)
        expect(tick.low_price).to eq(3.0)
        expect(tick.close_price).to eq(4.0)

        expect(tick.base_volume).to eq(2.0)
        expect(tick.target_volume).to eq(3.0)
      end
    end

    context "without volume" do
      let(:hash) { { "ot" => open_time, "ct" => current_time.to_i, "o" => 1.0, "c" => 1.0, "l" => 1.0, "h" => 1.0 } }

      it "has the correct attributes" do
        expect(tick.close_timestamp).to eq(current_time)
        expect(tick.close_price).to eq(1.0)
        expect(tick.base_volume).to eq(0.0)
        expect(tick.target_volume).to eq(0.0)
      end
    end
  end

  describe ".from_json" do
    let(:json) { Oj.dump({ "ot" => open_time, "ct" => close_time, "c" => 1.0, "bv" => 2.0, "tv" => 3.0 }) }

    subject(:tick) { described_class.from_json(json, tick_class: tick_class) }

    context "valid" do
      it { is_expected.to be_a(tick_class) }

      it "has the correct attributes" do
        expect(tick.open_timestamp).to eq(open_time)
        expect(tick.close_timestamp).to eq(close_time)
        expect(tick.close_price).to eq(1.0)
        expect(tick.base_volume).to eq(2.0)
        expect(tick.target_volume).to eq(3.0)
      end
    end
  end
end
