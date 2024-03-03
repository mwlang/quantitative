# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Ticks::Serializers::Spot do
  let(:current_time) { Quant.current_time.round }
  let(:one_second) { 1 }
  let(:tick_class) { Quant::Ticks::Spot }

  describe ".from" do
    let(:hash) { { "ct" => current_time.to_i, "cp" => 1.0, "bv" => 2.0, "tv" => 3.0 } }

    subject(:tick) { described_class.from(hash, tick_class:) }

    context "valid" do
      it { is_expected.to be_a(tick_class) }

      it "has the correct attributes" do
        expect(tick.close_timestamp).to eq(current_time)
        expect(tick.close_price).to eq(1.0)
        expect(tick.base_volume).to eq(2.0)
        expect(tick.target_volume).to eq(3.0)
      end

      describe "#to_h" do
        subject { tick.to_h }

        it { expect(subject["ct"]).to eq(current_time) }
        it { expect(subject["cp"]).to eq(1.0) }
        it { expect(subject["bv"]).to eq(2.0) }
        it { expect(subject["tv"]).to eq(3.0) }
      end
    end

    context "without volume" do
      let(:hash) { { "ct" => current_time.to_i, "cp" => 1.0 } }

      it "has the correct attributes" do
        expect(tick.close_timestamp).to eq(current_time)
        expect(tick.close_price).to eq(1.0)
        expect(tick.base_volume).to eq(0.0)
        expect(tick.target_volume).to eq(0.0)
      end
    end
  end

  describe ".from_json" do
    let(:json) { Oj.dump({ "ct" => current_time, "cp" => 1.0, "bv" => 2.0, "tv" => 3.0 }) }

    subject(:tick) { described_class.from_json(json, tick_class:) }

    context "valid" do
      it { is_expected.to be_a(tick_class) }

      it "has the correct attributes" do
        expect(tick.close_timestamp).to eq(current_time)
        expect(tick.close_price).to eq(1.0)
        expect(tick.base_volume).to eq(2.0)
        expect(tick.target_volume).to eq(3.0)
      end
    end
  end
end
