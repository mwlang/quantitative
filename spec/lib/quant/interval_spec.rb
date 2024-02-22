# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Interval do
  let(:current_time) { Quant.current_time }
  let(:one_minute_in_seconds) { 60 }
  let(:one_hour_in_seconds) { 3600 }
  let(:four_hours_in_seconds) { 14_400 }

  describe "new" do
    it { expect(described_class.new("1s").interval).to eq "1s" }
    it { expect(described_class.new(:"1m").interval).to eq "1m" }
    it { expect(described_class.new(:na).interval).to eq "na" }
    it { expect(described_class.new("na").interval).to eq "na" }

    it { expect(described_class.new("na").to_s).to eq "na" }
    it { expect(described_class.new(:"1m").to_s).to eq "1m" }
  end

  describe "equality" do
    let(:interval) { described_class.new("1d") }
    let(:same) { described_class.new("1d") }
    let(:different) { described_class.new("3m") }
    let(:as_string) { "1d" }
    let(:as_symbol) { :daily }

    it { expect(interval).to eq same }
    it { expect(interval).not_to eq different }
    it { expect(interval).to eq as_string }
    it { expect(interval).to eq as_symbol }
  end

  describe "na" do
    subject { described_class.na }

    it { is_expected.to eq described_class.new("na") }
    it { is_expected.to eq Quant::Interval[:na] }
    it { is_expected.to eq Quant::Interval["na"] }
    it { is_expected.to be_nil }
    it { is_expected.to be_na }
    it { expect(subject.duration).to eq 0 }
  end

  describe "nil" do
    subject { described_class.new(nil) }

    it { is_expected.to eq described_class.new("na") }
    it { is_expected.to be_nil }
    it { is_expected.to be_na }
  end

  describe "singleton methods" do
    it { expect(described_class.second.interval).to eq "1s" }
    it { expect(described_class.second).to eq described_class.new("1s") }
    it { expect(described_class.monthly).to eq described_class.new("1M") }
    it { expect(described_class.na).to eq described_class.new("na") }
  end

  describe "daily?" do
    it { expect(described_class.daily.daily?).to eq true }
    it { expect(described_class.hour.daily?).to eq false }
  end

  describe "#[]" do
    it { expect(Quant::Interval["1s"]).to eq described_class.new("1s") }
    it { expect(Quant::Interval["1s"]).to eq described_class.new("1s") }
    it { expect(Quant::Interval["1m"]).to eq described_class.minute }
    it { expect(Quant::Interval[nil]).to eq described_class.new("na") }
    it { expect(Quant::Interval[:daily]).to eq described_class.new("1d") }
    it { expect(Quant::Interval["1d"]).to eq described_class.new("1d") }
  end

  describe "seconds" do
    it { expect(described_class.second.seconds).to eq 1 }
    it { expect(Quant::Interval["1m"].seconds).to eq one_minute_in_seconds }
    it { expect(described_class.five_minutes.seconds).to eq 300 }
  end

  describe "duration" do
    it { expect(described_class.second.duration).to eq 1 }
    it { expect(described_class.minute.duration).to eq one_minute_in_seconds }
    it { expect(described_class.five_minutes.duration).to eq 300 }
  end

  describe "valid_intervals" do
    it "raises error if interval is invalid" do
      expect { described_class.new("1x") }.to raise_error(Quant::Errors::InvalidInterval)
    end

    it "treats all defined intervals as valid" do
      Quant::Interval::MAPPINGS.each_pair do |name, values|
        expect(described_class.valid_intervals).to include values[:interval]
      end
    end
  end

  describe ".[](value)" do
    subject { Quant::Interval[value] }
    context "when :daily" do
      let(:value) { :daily }
      it { is_expected.to eq described_class.daily }
    end
  end

  describe "#half_life" do
    it { expect(described_class.second.half_life).to eq 0.5 }
    it { expect(described_class.minute.half_life).to eq 30 }
  end

  describe "#next_interval" do
    it { expect(described_class.second.next_interval).to eq described_class.new("2s") }
    it { expect(described_class.minute.next_interval).to eq described_class.three_minutes }
    it "does not advance beyond monthly" do
      expect(described_class.monthly.next_interval).to eq described_class.monthly
    end
    it "computes -60 ticks for an hour ago on minute interval" do
      expect(described_class.minute.ticks_to(current_time - one_hour_in_seconds)).to eq(-60)
    end
  end

  describe "#ticks_to" do
    it "computes 60 ticks for 1s intervals for next minute" do
      expect(described_class.second.ticks_to(current_time + one_minute_in_seconds)).to eq 60
    end
    it "computes 20 ticks for 3s intervals for next minute" do
      expect(described_class.three_seconds.ticks_to(current_time + one_minute_in_seconds)).to eq 20
    end
    it "computes 2 ticks for 30 second intervals for next minute" do
      expect(described_class.thirty_seconds.ticks_to(current_time + one_minute_in_seconds)).to eq 2
    end
    it "computes 1 tick for 1 minute intervals for next minute" do
      expect(described_class.minute.ticks_to(current_time + one_minute_in_seconds)).to eq 1
    end
    it "computes 4 ticks for hour intervals for next 4 hours" do
      expect(described_class.hour.ticks_to(current_time + four_hours_in_seconds)).to eq 4
    end

    context "edge cases!" do
      it "computes 1 tick for hour intervals for next minute" do
        expect(described_class.hour.ticks_to(current_time + one_minute_in_seconds)).to eq 1
        expect(described_class.minute.ticks_to(current_time + one_minute_in_seconds)).to eq 1
        expect(described_class.three_minutes.ticks_to(current_time + one_minute_in_seconds)).to eq 1
      end
      it "computes 0 ticks for current time" do
        expect(described_class.hour.ticks_to(current_time)).to eq 0
      end
    end
  end

  describe "#timestamp_for" do
    let(:ts) { current_time.utc }

    it { expect(described_class.minute.timestamp_for(ticks: 0, timestamp: ts)).to eq(ts) }
    it { expect(described_class.minute.timestamp_for(ticks: 1, timestamp: ts)).to eq(ts + 60) }
    it { expect(described_class.second.timestamp_for(ticks: 60, timestamp: ts)).to eq(ts + 60) }
    it { expect(described_class.second.timestamp_for(ticks: -60, timestamp: ts)).to eq(ts - 60) }
  end
end