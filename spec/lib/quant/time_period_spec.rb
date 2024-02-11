# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::TimePeriod do
  let(:current_time) { Quant.current_time }
  let(:one_day_in_seconds) { 24 * 60 * 60 }
  let(:five_days_in_seconds) { 5 * one_day_in_seconds }
  let(:one_second) { 1 }

  context "when upper-bound" do
    subject { described_class.new(end_at: current_time) }

    it { is_expected.to be_upper_bound }
    it { is_expected.not_to be_lower_bound }
    it { expect(subject.start_at).to eq Quant::TimeMethods.epoch_time }
    it { expect(subject.start_at.utc.year).to eq 1492 }
    it { expect(subject).to cover(current_time - five_days_in_seconds) }
    it { expect(subject).not_to cover(current_time + five_days_in_seconds) }
    it { expect(subject).to cover(current_time - 105 * one_day_in_seconds) }

    context "when span given" do
      subject { described_class.new(end_at: current_time, span: five_days_in_seconds) }

      it { expect(subject.end_at).to be_within(one_second).of(current_time) }
      it { expect(subject.start_at).to be_within(one_second).of(current_time - five_days_in_seconds) }
      it { is_expected.to be_lower_bound }
      it { expect(subject).to cover(current_time - five_days_in_seconds + one_second) }
      it { expect(subject).not_to cover(current_time + five_days_in_seconds) }
      it { expect(subject).not_to cover(current_time - 105 * one_day_in_seconds) }
    end
  end

  context "when lower-bound" do
    subject { described_class.new(start_at: current_time) }

    it { is_expected.to be_lower_bound }
    it { is_expected.not_to be_upper_bound }
    it { expect(subject.end_at).to be_within(one_second).of(current_time) }

    context "when span given" do
      subject { described_class.new(start_at: current_time, span: five_days_in_seconds) }

      it { expect(subject.start_at).to be_within(one_second).of(current_time) }
      it { expect(subject.end_at).to be_within(one_second).of(current_time + five_days_in_seconds) }
      it { is_expected.to be_upper_bound }
    end
  end
end
