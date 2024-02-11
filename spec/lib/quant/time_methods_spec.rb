# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::TimeMethods do
  class TimeMethodsTest
    include Quant::TimeMethods
  end

  let(:instance) { TimeMethodsTest.new }

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
