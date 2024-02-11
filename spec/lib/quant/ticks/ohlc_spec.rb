# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Ticks::OHLC do
  describe ".from" do
    let(:one_second) { 1 }
    let(:one_minute_in_seconds) { 60 * one_second }
    let(:two_minutes_in_seconds) { 2 * one_minute_in_seconds }
    let(:open_time) { Quant.current_time }
    let(:close_time) { open_time + one_minute_in_seconds }
    let(:interval) { "1m" }
    let(:json) { { "ot" => open_time.to_i, "ct" => close_time, "iv" => "1m", "o" => 1.0, "bv" => 2.0, "tv" => 3.0 } }

    subject { described_class.from(json) }

    context "valid" do
      it { is_expected.to be_a(described_class) }

      it "has the correct attributes" do
        expect(subject.open_timestamp).to be_within(one_second).of(open_time)
        expect(subject.open_price).to eq(1.0)
        expect(subject.base_volume).to eq(2.0)
        expect(subject.target_volume).to eq(3.0)
      end
    end

    context "without volume" do
      let(:json) { { "ot" => open_time.to_i, "ct" => close_time, "iv" => "1m", "o" => 1.0 } }

      it "has the correct attributes" do
        expect(subject.open_timestamp).to be_within(one_second).of(open_time)
        expect(subject.close_timestamp).to eq(close_time)
        expect(subject.interval).to eq(Quant::Interval["1m"])
        expect(subject.open_price).to eq(1.0)
        expect(subject.base_volume).to eq(0.0)
        expect(subject.target_volume).to eq(0.0)
      end
    end

    context "without volume" do
      let(:json) do
        { "ot" => open_time.to_i,
          "ct" => close_time,
          "iv" => "1m",
          "o" => 1.0,
          "h" => 2.0,
          "l" => 0.5,
          "c" => 1.5,
          "bv" => 6.0,
          "tv" => 5.0,
          "t" => 1,
          "g" => true,
          "j" => true }
      end

      it "has the correct attributes" do
        expect(subject.open_timestamp).to be_within(one_second).of(open_time)
        expect(subject.close_timestamp).to eq(close_time)
        expect(subject.interval).to eq(Quant::Interval["1m"])

        expect(subject.open_price).to eq(1.0)
        expect(subject.high_price).to eq(2.0)
        expect(subject.low_price).to eq(0.5)
        expect(subject.close_price).to eq(1.5)

        expect(subject.base_volume).to eq(6.0)
        expect(subject.target_volume).to eq(5.0)

        expect(subject.trades).to eq(1)
        expect(subject.green).to eq(true)
        expect(subject.doji).to eq(true)
      end
    end

    context "#doji?" do
      subject { described_class.from(json).doji? }

      context "is true because of computation" do
        let(:json) do
          { "ot" => open_time,
            "ct" => close_time,
            "iv" => "1m",
            "o" => 3.0,
            "h" => 6.0,
            "l" => 1.0,
            "c" => 3.0,
            "j" => nil }
        end
        it { is_expected.to eq(true) }
      end

      context "passed false for doji and skips computation" do
        let(:json) do
          { "ot" => open_time,
            "ct" => close_time,
            "iv" => "1m",
            "o" => 3.0,
            "h" => 6.0,
            "l" => 1.0,
            "c" => 3.0,
            "j" => false }
        end

        it { is_expected.to eq(false) }
      end

      context "passed true for doji and skips computation" do
        let(:json) do
          { "ot" => open_time,
            "ct" => close_time,
            "iv" => "1m",
            "o" => 6.0,
            "h" => 6.0,
            "l" => 6.0,
            "c" => 6.0,
            "j" => true }
        end

        it { is_expected.to eq(true) }
      end
    end

    context "#green?" do
      subject { described_class.from(json).green? }

      context "is true because of computation" do
        let(:json) do
          { "ot" => open_time,
            "ct" => close_time,
            "iv" => "1m",
            "o" => 3.0,
            "h" => 6.0,
            "l" => 1.0,
            "c" => 4.0,
            "g" => nil }
        end
        it { is_expected.to eq(true) }
      end

      context "passed false for doji and skips computation" do
        let(:json) do
          { "ot" => open_time,
            "ct" => close_time,
            "iv" => "1m",
            "o" => 3.0,
            "h" => 6.0,
            "l" => 1.0,
            "c" => 3.0,
            "g" => false }
        end

        it { is_expected.to eq(false) }
      end
    end

    context "#doji?" do
      subject { described_class.from(json).doji? }

      context "passed true for doji and skips computation" do
        let(:json) do
          { "ot" => open_time,
            "ct" => close_time,
            "iv" => "1m",
            "o" => 6.0,
            "h" => 6.0,
            "l" => 6.0,
            "c" => 6.0,
            "j" => true }
        end

        it { is_expected.to eq(true) }
      end
    end

    describe "#corresponding?" do
      let(:time_1) { Quant.current_time }
      let(:time_2) { time_1 + two_minutes_in_seconds }
      let(:hash_1) do
        { "ot" => time_1,
          "ct" => time_1 + one_minute_in_seconds,
          "iv" => "1m",
          "o" => 6.0,
          "h" => 6.0,
          "l" => 6.0,
          "c" => 6.0,
          "g" => true }
      end

      let(:hash_2) do
        { "ot" => time_2,
          "ct" => time_2 + one_minute_in_seconds,
          "iv" => "1m",
          "o" => 3.0,
          "h" => 3.0,
          "l" => 3.0,
          "c" => 3.0,
          "g" => true }
      end

      context "when same timestamps" do
        let(:tick1) { described_class.from(hash_1) }
        let(:tick2) { described_class.from(hash_1.merge(hash_2.except("ot", "ct"))) }

        it { expect(tick1).to be_corresponding tick2 }
      end

      context "when different timestamps" do
        let(:tick1) { described_class.from(hash_1) }
        let(:tick2) { described_class.from(hash_2) }

        it { expect(tick1).not_to be_corresponding tick2 }

        context "when same open_timestamp, different close_timestamp" do
          let(:tick2) { described_class.from(hash_2.merge(hash_2.except("ct"))) }

          it { expect(tick1).not_to be_corresponding tick2 }
        end
      end
    end

    describe "#assign_series" do
      let(:first_series) { double("first_series") }
      let(:next_series) { double("next_series") }

      let(:json) do
        { "ot" => open_time,
          "ct" => close_time,
          "iv" => "1m",
          "o" => 6.0,
          "h" => 6.0,
          "l" => 6.0,
          "c" => 6.0,
          "g" => true }
      end

      let(:tick) { described_class.from(json) }

      before { tick.assign_series(first_series) }

      subject { tick }

      context "first time" do
        it { is_expected.to eq tick }
        it { expect(subject.series).to eq first_series }
        it { expect { subject }.not_to change { tick.to_h } }
      end

      xcontext "second time" do
        before { tick.assign_series(first_series) }

        subject { tick.assign_series(next_series) }

        it { expect(subject.series).to eq first_series }
        it { expect(subject).to eq tick }
        it { expect(subject).not_to eql tick }
        it { expect(subject).not_to be tick }
        it { expect { subject }.not_to change { tick.to_h } }
        it { expect(subject.to_h).to eq tick.to_h }
      end
    end
  end
end
