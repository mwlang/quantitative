# frozen_string_literal: true

module Quant
  RSpec.describe Settings::Indicators do
    context "all defaults" do
      subject { described_class.defaults }

      it { expect(subject.max_period).to eq Settings::MAX_PERIOD }
      it { expect(subject.min_period).to eq Settings::MIN_PERIOD }
      it { expect(subject.half_period).to eq Settings::HALF_PERIOD }
      it { expect(subject.pivot_kind).to eq Settings::PIVOT_KINDS.first }
      it { expect(subject.dominant_cycle_kind).to eq Settings::DOMINANT_CYCLE_KINDS.first }
    end

    context "custom settings" do
      subject do
        described_class.new(
          max_period: 10,
          min_period: 4,
          micro_period: 2,
          pivot_kind: :fibbonacci
        )
      end

      it { expect(subject.max_period).to eq 10 }
      it { expect(subject.min_period).to eq 4 }
      it { expect(subject.half_period).to eq 7 }
      it { expect(subject.micro_period).to eq 2 }
      it { expect(subject.pivot_kind).to eq :fibbonacci }
    end
  end
end
