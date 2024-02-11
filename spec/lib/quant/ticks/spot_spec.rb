# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Ticks::Spot do
  let(:current_time) { Quant.current_time }
  let(:one_second) { 1 }

  describe ".from" do
    let(:close_time) { current_time.round }
    let(:hash) { { "ct" => close_time.to_i, "c" => 1.0, "bv" => 2.0, "tv" => 3.0 } }

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
      let(:hash) { { "ct" => close_time.to_i, "c" => 1.0 } }

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
    let(:json) { Oj.dump({ "ct" => close_time, "c" => 1.0, "bv" => 2.0, "tv" => 3.0 }) }

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

  describe "equality" do
    let(:time_1) { current_time.round(0) }
    let(:time_2) { time_1 + one_second }

    context "when same timestamps" do
      let(:tick1) { described_class.new(close_timestamp: time_1, close_price: 1.0) }
      let(:tick2) { described_class.new(close_timestamp: time_1, close_price: 1.0) }

      it { expect(tick1).to eq tick2 }

      context "when different close_price" do
        let(:tick2) { described_class.new(close_timestamp: time_1, close_price: 2.0) }

        it { expect(tick1).not_to eq tick2 }
      end
    end

    context "when different timestamps" do
      let(:tick1) { described_class.new(close_timestamp: time_1, close_price: 1.0) }
      let(:tick2) { described_class.new(close_timestamp: time_2, close_price: 1.0) }

      it { expect(tick1).not_to eq tick2 }
    end
  end

  describe "#corresponding?" do
    let(:time_1) { current_time.round(0) }
    let(:time_2) { time_1 + one_second }

    context "when same timestamps" do
      let(:tick1) { described_class.new(close_timestamp: time_1, close_price: 1.0) }
      let(:tick2) { described_class.new(close_timestamp: time_1, close_price: 1.0) }

      it { expect(tick1).to be_corresponding tick2 }
    end

    context "when different timestamps" do
      let(:tick1) { described_class.new(close_timestamp: time_1, close_price: 1.0) }
      let(:tick2) { described_class.new(close_timestamp: time_2, close_price: 1.0) }

      it { expect(tick1).not_to be_corresponding tick2 }
    end
  end

  describe "#assign_series" do
    let(:first_series) { double("first_series") }
    let(:next_series) { double("next_series") }

    let(:tick) { described_class.new(close_timestamp: current_time, close_price: 1.0) }

    before { tick.assign_series(first_series) }

    subject { tick }

    context "first time" do
      it { expect { subject }.not_to change { tick.to_h } }

      it "assigns new series without duping the tick" do
        expect(subject.series).to eq first_series
        expect(subject).to eql tick
        expect(subject).to be tick
        expect(subject.to_h).to eq tick.to_h
      end

      context "switching series" do
        before { tick.assign_series!(next_series) }

        it "does not dup the tick when setting new series" do
          expect(subject.series).to eq next_series
          expect(subject).to eql tick
          expect(subject).to be tick
          expect(subject.to_h).to eq tick.to_h
        end
      end
    end

    context "second time" do
      before { tick.assign_series(first_series) }

      subject { tick.assign_series(next_series) }

      it { expect { subject }.not_to change { tick.to_h } }

      xit "dups the tick keeps original series" do
        expect(subject.series).to eq first_series
        expect(subject).not_to eql tick
        expect(subject).not_to be tick
        expect(subject).to eq tick
        expect(subject.to_h).to eq tick.to_h
      end

      xit "keeps the original indicator points" do
        ip = tick.indicators
        expect(subject.indicators).to eq ip
      end
    end
  end
end