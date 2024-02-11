# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Ticks::Value do
  describe ".from" do
    let(:one_second) { 1 }
    let(:open_time) { Quant.current_time }
    let(:close_time) { open_time + 1.minute }
    let(:interval) { "1m" }

    subject { described_class.new(price: 1.25, volume: 500) }

    context "valid" do
      it { is_expected.to be_a(described_class) }

      it "has timestamps" do
        expect(subject.open_timestamp).to be_within(one_second).of(open_time)
        expect(subject.close_timestamp).to be_within(one_second).of(open_time)
        expect(subject.close_timestamp).to eq subject.open_timestamp
      end

      it "has no interval" do
        expect(subject.interval).to be_nil
        expect(subject.interval).to be_na
        expect(subject.interval).to be_a Quant::Interval
      end

      it "has all prices" do
        expect(subject.open_price).to eq(1.25)
        expect(subject.high_price).to eq(1.25)
        expect(subject.low_price).to eq(1.25)
        expect(subject.close_price).to eq(1.25)
      end

      it "has common price calculations" do
        expect(subject.oc2).to eq(1.25)
        expect(subject.hlc3).to eq(1.25)
        expect(subject.ohlc4).to eq(1.25)
      end

      it "has volume" do
        expect(subject.base_volume).to eq(500)
        expect(subject.target_volume).to eq(500)
        expect(subject.volume).to eq(500)
      end
    end

    context "with interval" do
      subject { described_class.new(price: 1.25, interval: :daily, volume: 500) }
      it { expect(subject.interval).to eq Quant::Interval.daily }
    end

    context "without volume" do
      subject { described_class.new(price: 1.25) }

      it "has zero volume" do
        expect(subject.base_volume).to eq(0)
        expect(subject.target_volume).to eq(0)
      end
    end

    describe "#to_h" do
      let(:current_time) { Quant.current_time }

      subject { described_class.new(price: 1.25, timestamp: current_time, interval: :daily, volume: 500).to_h }

      let(:expected_hash) do
        {
          "iv" => "1d",
          "ct" => current_time.to_i,
          "cp" => 1.25,
          "bv" => 500,
          "tv" => 500,
        }
      end

      it { is_expected.to be_a Hash }
      it { is_expected.to eq expected_hash }

      describe "#to_json" do
        subject { described_class.new(price: 1.25, timestamp: current_time, interval: :daily, volume: 500).to_json }

        let(:expected_json) { "{\"iv\":\"1d\",\"ct\":#{current_time.to_i},\"cp\":1.25,\"bv\":500,\"tv\":500}" }

        it { is_expected.to eq expected_json }
      end
    end
  end
end
