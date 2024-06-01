# frozen_string_literal: true

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

    describe "#inspect" do
      let(:tick) do
        described_class.new(
          open_price: 1.0,
          high_price: 2.0,
          low_price: 3.0,
          close_price: 4.0,
          open_timestamp: Time.utc(2024, 1, 15, 8, 30, 5),
          close_timestamp: Time.utc(2024, 1, 15, 8, 30, 5),
          volume: 88
        )
      end

      it { expect(tick.inspect).to eq("#<Quant::Ticks::OHLC ct=2024-01-15T08:30:05Z o=1.0 h=2.0 l=3.0 c=4.0 v=88>") }
    end

    describe "equality" do
      let(:attributes) do
        { open_price: 1.0,
          high_price: 2.0,
          low_price: 3.0,
          close_price: 4.0,
          open_timestamp: open_time,
          close_timestamp: close_time }
      end
      let(:tick1) { described_class.new(**attributes) }
      let(:tick2) { described_class.new(**attributes) }
      let(:tick3) { described_class.new(**attributes.merge(close_price: 5.0)) }
      let(:expected_hash) do
        { "bv" => 0,
          "c" => 4.0,
          "ct" => close_time,
          "g" => true,
          "h" => 2.0,
          "j" => false,
          "l" => 3.0,
          "o" => 1.0,
          "ot" => open_time,
          "t" => 0,
          "tv" => 0 }
      end
      it { expect(tick1).to eq tick2 }
      it { expect(tick1).not_to eq tick3 }
      it { expect(tick1.to_h).to eq expected_hash }
      it { expect(tick1.daily_price_change).to eq(-0.75) }
      it { expect(subject.daily_price_change_ratio).to eq(2.0) }
    end

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
      let(:json) { { "ot" => open_time.to_i, "ct" => close_time, "o" => 1.0 } }

      it "has the correct attributes" do
        expect(subject.open_timestamp).to be_within(one_second).of(open_time)
        expect(subject.close_timestamp).to eq(close_time)
        expect(subject.open_price).to eq(1.0)
        expect(subject.base_volume).to eq(0.0)
        expect(subject.target_volume).to eq(0.0)
        expect(subject.daily_price_change).to eq(-1.0)
      end
    end

    context "without volume" do
      let(:json) do
        { "ot" => open_time.to_i,
          "ct" => close_time,
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
        expect(subject.interval).to be_nil

        expect(subject.open_price).to eq(1.0)
        expect(subject.high_price).to eq(2.0)
        expect(subject.low_price).to eq(0.5)
        expect(subject.close_price).to eq(1.5)
        expect(subject.daily_price_change).to eq(-0.33333333333333337)
        expect(subject.daily_price_change_ratio).to eq(0.4)

        expect(subject.base_volume).to eq(6.0)
        expect(subject.target_volume).to eq(5.0)

        expect(subject.trades).to eq(1)
        expect(subject).to be_green
        expect(subject).not_to be_red
        expect(subject).to be_doji
      end
    end

    context "#doji?" do
      subject { described_class.from(json).doji? }

      context "is true because of computation" do
        let(:json) do
          { "ot" => open_time,
            "ct" => close_time,
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

    context "#green? and #red?" do
      subject { described_class.from(json) }

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
        it { is_expected.to be_green }
        it { is_expected.not_to be_red }
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

        it { is_expected.not_to be_green }
        it { is_expected.to be_red }
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
      let(:opent_time) { Quant.current_time }
      let(:close_time) { open_time + two_minutes_in_seconds }
      let(:hash1) do
        { "ot" => open_time,
          "ct" => open_time + one_minute_in_seconds,
          "iv" => "1m",
          "o" => 6.0,
          "h" => 6.0,
          "l" => 6.0,
          "c" => 6.0,
          "g" => true }
      end
      let(:hash2) do
        { "ot" => close_time,
          "ct" => close_time + one_minute_in_seconds,
          "iv" => "1m",
          "o" => 3.0,
          "h" => 3.0,
          "l" => 3.0,
          "c" => 3.0,
          "g" => true }
      end

      context "when same timestamps" do
        let(:tick1) { described_class.from(hash1) }
        let(:tick2) { described_class.from(hash1.merge(hash2.except("ot", "ct"))) }

        it { expect(tick1).to be_corresponding tick2 }
      end

      context "when different timestamps" do
        let(:tick1) { described_class.from(hash1) }
        let(:tick2) { described_class.from(hash2) }

        it { expect(tick1).not_to be_corresponding tick2 }

        context "when same open_timestamp, different close_timestamp" do
          let(:tick2) { described_class.from(hash2.merge(hash2.except("ct"))) }

          it { expect(tick1).not_to be_corresponding tick2 }
        end
      end
    end

    describe "#assign_series" do
      let(:indicators) { instance_double(Quant::IndicatorsSources) }
      let(:first_series) { instance_double(Quant::Series, interval: "1d", indicators:) }
      let(:next_series) { instance_double(Quant::Series) }
      let(:json) do
        { "ot" => open_time,
          "ct" => close_time,
          "o" => 6.0,
          "h" => 6.0,
          "l" => 6.0,
          "c" => 6.0,
          "g" => true }
      end
      let(:tick) { described_class.from(json) }

      before do
        allow(indicators).to receive(:<<) { |tick| tick }
        tick.assign_series(first_series)
      end

      subject { tick }

      context "first time" do
        it { is_expected.to eq tick }
        it { expect(subject.series).to eq first_series }
        it { expect(subject.interval).to eq "1d" }
        it { expect { subject }.not_to change { tick.to_h } }

        context "when tick.interval is nil before assigning" do
          let(:json) do
            { "ot" => open_time,
              "ct" => close_time,
              "o" => 6.0,
              "h" => 6.0,
              "l" => 6.0,
              "c" => 6.0,
              "g" => true }
          end

          it { expect(subject.interval).to eq "1d" }
        end
      end

      context "second time" do
        before { tick.assign_series(first_series) }

        subject { tick.assign_series(next_series) }

        it { expect(subject.series).to eq first_series }
        it { expect(subject).to eq tick }
        it { expect { subject }.not_to change { tick.to_h } }
        it { expect(subject.interval).to eq "1d" }
        it { expect(subject.to_h).to eq tick.to_h }
      end
    end
  end
end
