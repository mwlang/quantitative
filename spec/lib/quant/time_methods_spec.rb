# frozen_string_literal: true

RSpec.describe Quant::TimeMethods do
  let(:time_test_class) do
    Class.new do
      include Quant::TimeMethods
    end
  end

  let(:instance) { time_test_class.new }

  describe "#extract_time" do
    let(:expected_time) { Time.new(2023, 11, 12, 8, 31, 25).utc }

    subject { instance.extract_time(time) }

    context "when nil" do
      let(:time) { nil }
      it { expect { subject }.to raise_error(ArgumentError, "Invalid time: nil") }
    end

    context "when a Time" do
      let(:time) { expected_time }
      it { is_expected.to eq(expected_time) }

      context "when current_time" do
        let(:time) { Quant.current_time }
        it { is_expected.to be_within(1).of(Time.now) }
      end

      context "when epoch_time" do
        let(:time) { described_class.epoch_time }
        it { is_expected.to be < (Time.at(0)) }
      end
    end

    context "when a Date" do
      let(:time) { Date.civil(2023, 11, 12) }
      it { is_expected.to eq(Time.utc(2023, 11, 12, 0, 0, 0)) }

      context "when current_date" do
        let(:time) { Quant.current_date }
        it { is_expected.to eq(Time.utc(time.year, time.month, time.day, 0, 0, 0)) }
      end

      context "when epoch_date" do
        let(:time) { described_class.epoch_date }
        it { is_expected.to be < (Time.at(0)) }
      end
    end

    context "when an DateTime" do
      let(:time) { DateTime.new(2023, 11, 12, 8, 31, 25, 0, 0) }
      it { is_expected.to eq(expected_time) }
    end

    context "when an Integer" do
      let(:time) { expected_time.to_i }
      it { is_expected.to eq(expected_time) }
    end

    context "when a String" do
      context "without timezone" do
        let(:time) { "2023-11-12T08:31:25" }
        it { is_expected.to eq(expected_time) }
      end

      context "ET timezone" do
        let(:time) { "2023-11-12T08:31:25TZ+500" }
        it { is_expected.to eq(expected_time) }
      end

      context "UTC timezone" do
        let(:time) { "2023-11-12T08:31:25TZ" }
        it { is_expected.to eq(expected_time) }
      end
    end
  end
end
