# frozen_string_literal: true

require "spec_helper"

module IndicatorSpec
  class NoOpPoint < Quant::Indicators::IndicatorPoint
    attr_reader :input
  end

  RSpec.describe Quant::Indicators::Indicator do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
    let(:source) { :oc2 }

    let(:noop_indicator_class) do
      NoOpIndicator ||= Class.new(described_class) do
        def periods
          @periods ||= []
        end

        def compute
          periods << dc_period
        end

        def points_class
          NoOpPoint
        end
      end
    end

    it { expect { described_class.new(series:, source:).compute }.to raise_error(NotImplementedError) }

    subject { noop_indicator_class.new(series:, source:) }

    it { is_expected.to be_a(described_class) }
    it { expect(subject.inspect).to eq("#<IndicatorSpec::NoOpIndicator symbol=DEUCES source=oc2 ticks=4>") }

    it { expect(subject.series.size).to eq(4) }
    it { expect(subject.ticks.size).to eq(4) }
    it { expect(subject.ticks.first).to eq(series.ticks.first) }
    it { expect(subject.ticks.last).to eq(series.ticks.last) }
    it { expect(subject.values.size).to eq(4) }

    it { expect(subject.min_period).to eq(10) }
    it { expect(subject.max_period).to eq(48) }

    it { expect(subject.p0).to eq subject.values[-1] }
    it { expect(subject.p1).to eq subject.values[-2] }
    it { expect(subject.p2).to eq subject.values[-3] }
    it { expect(subject.p3).to eq subject.values[-4] }

    it { expect(subject.p0).to eq subject.values[3] }
    it { expect(subject.p1).to eq subject.values[2] }
    it { expect(subject.p2).to eq subject.values[1] }
    it { expect(subject.p3).to eq subject.values[0] }

    it { expect(subject.p0).to eq subject.p(0) }
    it { expect(subject.p1).to eq subject.p(1) }
    it { expect(subject.p2).to eq subject.p(2) }
    it { expect(subject.p3).to eq subject.p(3) }
    it { expect(subject.p3).to eq subject.p(4) }

    it { expect(subject.t0).to eq subject.ticks[-1] }
    it { expect(subject.t1).to eq subject.ticks[-2] }
    it { expect(subject.t2).to eq subject.ticks[-3] }
    it { expect(subject.t3).to eq subject.ticks[-4] }

    it { expect(subject.t0).to eq subject.t(0) }
    it { expect(subject.t1).to eq subject.t(1) }
    it { expect(subject.t2).to eq subject.t(2) }
    it { expect(subject.t3).to eq subject.t(3) }

    it { expect(subject[0].input).to eq(3.0) }
    it { expect(subject[0]).to eq(subject.values.first) }
    it { expect(subject[-1]).to eq(subject.values.last) }
    it { expect(subject.periods.uniq).to eq [29] }

    describe "dominant_cycle" do
      let(:series) do
        # 40 bar sine wave
        Quant::Series.new(symbol: "SINE", interval: "1d").tap do |series|
          3.times do
            (0..39).each do |degree|
              radians = degree * 2 * Math::PI / 40
              series << 5.0 * Math.sin(radians) + 10.0
            end
          end
        end
      end

      before do
        Quant.configure_indicators(dominant_cycle_kind: :band_pass)
      end

      after(:all) { Quant.default_configuration! }

      it { expect(subject.periods.uniq).to eq([29, 36, 42, 40]) }
    end

    describe "values :input" do
      subject { noop_indicator_class.new(series:, source:).values.map(&:input) }

      context "when :oc2" do
        let(:source) { :oc2 }

        it { is_expected.to eq([3.0, 6.0, 12.0, 24.0]) }
      end

      context "when :open_price" do
        let(:source) { :open_price }

        it { is_expected.to eq([2.0, 4.0, 8.0, 16.0]) }
      end

      context "when :volume" do
        let(:source) { :volume }

        it { is_expected.to eq([100, 200, 300, 400]) }
      end
    end
  end
end