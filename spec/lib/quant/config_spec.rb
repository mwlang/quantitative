# frozen_string_literal: true

RSpec.describe Quant::Config do
  after(:all) { Quant.default_configuration! }

  describe "configuring indicators" do
    subject { Quant.config.indicators }

    describe "Quant.config.indicators" do
      it { is_expected.to be_a(Quant::Settings::Indicators) }
      it { expect(subject.max_period).to eq(Quant::Settings::MAX_PERIOD) }
      it { expect(subject.min_period).to eq(Quant::Settings::MIN_PERIOD) }
      it { expect(subject.half_period).to eq(Quant::Settings::HALF_PERIOD) }
      it { expect(subject.pivot_kind).to eq(Quant::Settings::PIVOT_KINDS.first) }
      it { expect(subject.dominant_cycle_kind).to eq(Quant::Settings::DOMINANT_CYCLE_KINDS.first) }
    end

    describe "Quant.configure_indicators" do
      context "by method arguments" do
        before do
          Quant.configure_indicators \
            max_period: 10,
            min_period: 4,
            micro_period: 2,
            pivot_kind: :fibbonacci
        end

        it { expect(subject.max_period).to eq(10) }
        it { expect(subject.min_period).to eq(4) }
        it { expect(subject.half_period).to eq(7) }
        it { expect(subject.micro_period).to eq(2) }
        it { expect(subject.pivot_kind).to eq(:fibbonacci) }
        it { expect(subject.dominant_cycle_kind).to eq(:half_period) }
      end

      context "by block" do
        before do
          Quant.configure_indicators do |config|
            config.max_period = 4
            config.min_period = 2
            config.micro_period = 4
            config.pivot_kind = :bollinger
          end
        end

        it { expect(subject.max_period).to eq(4) }
        it { expect(subject.min_period).to eq(2) }
        it { expect(subject.half_period).to eq(3) }
        it { expect(subject.micro_period).to eq(4) }
        it { expect(subject.dominant_cycle_kind).to eq(:half_period) }
        it { expect(subject.pivot_kind).to eq(:bollinger) }

        it "configures twice" do
          Quant.configure_indicators do |config|
            config.max_period = 12
            config.min_period = 6
            config.pivot_kind = :fibbonacci
            config.dominant_cycle_kind = :auto_correlation_reversal
          end

          expect(subject.max_period).to eq(12)
          expect(subject.min_period).to eq(6)
          expect(subject.half_period).to eq(9)
          expect(subject.micro_period).to eq(4)
          expect(subject.dominant_cycle_kind).to eq(:auto_correlation_reversal)
          expect(subject.pivot_kind).to eq(:fibbonacci)
        end
      end
    end
  end
end
