# frozen_string_literal: true

RSpec.describe Quant::TimePeriod do
  let(:current_time) { Quant.current_time }
  let(:current_time_beginning_of_day) { Time.utc(current_time.year, current_time.month, current_time.day, 0, 0, 0, 0) }
  let(:current_time_end_of_day) { current_time_beginning_of_day + one_day_in_seconds - one_second }
  let(:one_day_in_seconds) { 24 * 60 * 60 }
  let(:five_days_in_seconds) { 5 * one_day_in_seconds }
  let(:one_second) { 1 }

  context "when unbound" do
    subject { described_class.new(start_at: nil, end_at: nil) }

    it { expect{ subject }.to raise_error("TimePeriod cannot be unbound at start_at and end_at") }
  end

  context "when upper-bound" do
    subject { described_class.new(end_at: current_time) }

    it { is_expected.to be_upper_bound }
    it { is_expected.not_to be_lower_bound }
    it { expect(subject.start_at).to eq Quant::TimeMethods.epoch_time }
    it { expect(subject.start_at.utc.year).to eq 1492 }
    it { expect(subject).to cover(current_time - five_days_in_seconds) }
    it { expect(subject).not_to cover(current_time + five_days_in_seconds) }
    it { expect(subject).to cover(current_time - 105 * one_day_in_seconds) }
    it { expect(subject.duration).to be > five_days_in_seconds }

    context "when span given" do
      subject { described_class.new(end_at: current_time, span: five_days_in_seconds) }

      it { expect(subject.end_at).to be_within(one_second).of(current_time) }
      it { expect(subject.start_at).to be_within(one_second).of(current_time - five_days_in_seconds) }
      it { is_expected.to be_lower_bound }
      it { expect(subject).to cover(current_time - five_days_in_seconds + one_second) }
      it { expect(subject).not_to cover(current_time + five_days_in_seconds) }
      it { expect(subject).not_to cover(current_time - 105 * one_day_in_seconds) }
      it { expect(subject.duration).to eq five_days_in_seconds }
      it { expect(subject.to_h.keys).to eq [:start_at, :end_at]}

      context "when start_at Date given" do
        let(:current_date) { current_time.to_date }
        subject { described_class.new(start_at: current_date, span: five_days_in_seconds) }

        it { expect(subject.start_at).to be_within(one_second).of(current_time_beginning_of_day) }
        it { expect(subject.end_at).to be_within(one_second).of(current_time_beginning_of_day + five_days_in_seconds) }
        it { is_expected.to be_upper_bound }
        it { expect(subject).not_to cover(current_time - five_days_in_seconds + one_second) }
        it { expect(subject).to cover(current_time_beginning_of_day + five_days_in_seconds) }
        it { expect(subject).not_to cover(current_time - 105 * one_day_in_seconds) }
        it { expect(subject.duration).to eq five_days_in_seconds }
      end

      context "when end_at Date given" do
        subject { described_class.new(end_at: current_time.to_date, span: five_days_in_seconds) }

        it { expect(subject.end_at).to be_within(one_second).of(current_time_end_of_day) }
        it { expect(subject.start_at).to be_within(one_second).of(current_time_end_of_day - five_days_in_seconds) }
        it { is_expected.to be_lower_bound }
        it { expect(subject).to cover(current_time_end_of_day - five_days_in_seconds + one_second) }
        it { expect(subject).not_to cover(current_time + five_days_in_seconds) }
        it { expect(subject).not_to cover(current_time - 105 * one_day_in_seconds) }
        it { expect(subject.duration).to eq five_days_in_seconds }
      end
    end
  end

  context "when lower-bound" do
    subject { described_class.new(start_at: current_time) }

    it { is_expected.to be_lower_bound }
    it { is_expected.not_to be_upper_bound }
    it { expect(subject.end_at).to be_within(one_second).of(current_time) }
    it { expect(subject.duration).to eq 0.0 }

    context "when span given" do
      subject { described_class.new(start_at: current_time, span: five_days_in_seconds) }

      it { expect(subject.start_at).to be_within(one_second).of(current_time) }
      it { expect(subject.end_at).to be_within(one_second).of(current_time + five_days_in_seconds) }
      it { is_expected.to be_upper_bound }
    end
  end

  context "equality" do
    unbound_time = nil
    current_time = Quant.current_time
    later_time = current_time + 1
    earlier_time = current_time - 1

    [
      [unbound_time, current_time, unbound_time, current_time, true],
      [unbound_time, current_time, unbound_time, later_time, false],
      [unbound_time, current_time, current_time, later_time, false],

      [current_time, unbound_time, current_time, unbound_time, true],
      [current_time, unbound_time, later_time, unbound_time, false],
      [current_time, unbound_time, current_time, later_time, false],

      [current_time, later_time, current_time, later_time, true],
      [current_time, later_time, earlier_time, later_time, false],
      [current_time, later_time, earlier_time, current_time, false],
      [current_time, later_time, current_time, unbound_time, false],
      [current_time, later_time, unbound_time, later_time, false],

    ].each do |start_at, end_at, other_start_at, other_end_at, expected|
      it "when (#{start_at}..#{end_at}) #{expected ? "==" : "!="} (#{other_start_at}..#{other_end_at})" do
        interval = described_class.new(start_at:, end_at:)
        other = described_class.new(start_at: other_start_at, end_at: other_end_at)
        if expected
          expect(interval).to eq other
        else
          expect(interval).not_to eq other
        end
      end
    end
  end
end
