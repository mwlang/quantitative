# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Ticks::Spot do
  let(:current_time) { Quant.current_time }
  let(:one_second) { 1 }

  describe ".from" do
    let(:close_time) { current_time.round }
    let(:hash) { { "ct" => close_time.to_i, "cp" => 1.0, "bv" => 2.0, "tv" => 3.0 } }

    subject { described_class.from(hash) }

    context "valid" do
      it { is_expected.to be_a(described_class) }

      it "has the correct attributes" do
        expect(subject.close_timestamp).to eq(close_time)
        expect(subject.close_price).to eq(1.0)
        expect(subject.base_volume).to eq(2.0)
        expect(subject.target_volume).to eq(3.0)
      end
    end

    context "without volume" do
      let(:hash) { { "ct" => close_time.to_i, "cp" => 1.0 } }

      it "has the correct attributes" do
        expect(subject.close_timestamp).to eq(close_time)
        expect(subject.close_price).to eq(1.0)
        expect(subject.base_volume).to eq(0.0)
        expect(subject.target_volume).to eq(0.0)
      end
    end
  end

  describe ".from_json" do
    let(:close_time) { current_time }
    let(:json) { Oj.dump({ "ct" => close_time, "cp" => 1.0, "bv" => 2.0, "tv" => 3.0 }) }

    subject { described_class.from_json(json) }

    context "valid" do
      it { is_expected.to be_a(described_class) }

      it "has the correct attributes" do
        expect(subject.close_timestamp).to eq(close_time)
        expect(subject.close_price).to eq(1.0)
        expect(subject.base_volume).to eq(2.0)
        expect(subject.target_volume).to eq(3.0)
      end
    end
  end

  describe "#inspect" do
    let(:tick) do
      described_class.new(
        interval: :daily,
        close_price: 1.25,
        close_timestamp: Time.new(2024, 1, 15, 8, 30, 5),
        volume: 88
      )
    end

    it { expect(tick.inspect).to eq("#<Quant::Ticks::Spot 1d ct=2024-01-15 13:30:05 UTC c=1.25 v=88>") }
  end

  describe "#corresponding?" do
    let(:time1) { current_time }
    let(:time2) { current_time + one_second }

    context "when same timestamps" do
      let(:tick1) { described_class.new(close_timestamp: time1, close_price: 1.0) }
      let(:tick2) { described_class.new(close_timestamp: time1, close_price: 1000.0) }

      it { expect(tick1).to be_corresponding tick2 }
    end

    context "when different timestamps" do
      let(:tick1) { described_class.new(close_timestamp: time1, close_price: 1.0) }
      let(:tick2) { described_class.new(close_timestamp: time2, close_price: 1.0) }

      it { expect(tick1).not_to be_corresponding tick2 }
    end
  end

  describe "equality" do
    let(:time1) { current_time }
    let(:time2) { time1 + one_second }

    context "when same timestamps" do
      let(:tick1) { described_class.new(close_timestamp: time1, close_price: 1.0) }
      let(:tick2) { described_class.new(close_timestamp: time1, close_price: 1.0) }

      it { expect(tick1).to eq tick2 }

      context "when different close_price" do
        let(:tick2) { described_class.new(close_timestamp: time1, close_price: 2.0) }

        it { expect(tick1).not_to eq tick2 }
      end

      context "when different timestamps" do
        let(:tick2) { described_class.new(close_timestamp: time2, close_price: 1.0) }

        it { expect(tick1).not_to eq tick2 }
      end
    end
  end
end
