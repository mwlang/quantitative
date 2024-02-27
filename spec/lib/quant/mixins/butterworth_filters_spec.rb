# frozen_string_literal: true

require "spec_helper"

module ButterworthMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :bw2p, default: 0.0
    attribute :bw3p, default: 0.0
  end

  class TestIndicator < Quant::Indicators::Indicator
    include Quant::Mixins::ButterworthFilters

    def points_class
      TestPoint
    end

    def compute
      p0.bw2p = two_pole_butterworth(:input, period: 3, previous: :bw2p).round(3)
      p0.bw3p = three_pole_butterworth(:input, period: 3, previous: :bw3p).round(3)
    end
  end

  RSpec.describe Quant::Mixins::ButterworthFilters do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }

    subject { TestIndicator.new(series:, source: :oc2) }

    before { series.indicators.oc2.attach(indicator_class: TestIndicator, name: :sma) }

    context "deuces sample prices" do
      it { is_expected.to be_a(TestIndicator) }
      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
      it { expect(subject.values.map(&:bw2p)).to eq([3.033, 4.516, 9.126, 18.335]) }
      it { expect(subject.values.map(&:bw3p)).to eq([3.227, 6.21, 12.509, 25.017]) }
    end

    context "growing price" do
      let(:series) { Quant::Series.new(symbol: "BW", interval: "1d") }

      [[1, 1.011, 1.076],
       [2, 1.505, 2.07],
       [3, 2.536, 3.094],
       [4, 3.564, 4.092],
       [5, 4.563, 5.092],
       [6, 5.562, 6.092]].each do |n, bw2p_expected, bw3p_expected|
        dataset = (1..n).to_a

        it "is #{bw2p_expected.inspect} for 2 pole when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.bw2p).to eq bw2p_expected
        end

        it "is #{bw3p_expected.inspect} for 3 pole when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.bw3p).to eq bw3p_expected
        end
      end
    end

    context "static price" do
      using Quant

      let(:series) { Quant::Series.new(symbol: "BW", interval: "1d") }

      before { 25.times { series << 5.0 } }

      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to be_all(5.0) }
      it { expect(subject.values.map(&:bw2p).uniq).to eq([5.055, 4.999, 4.997, 5.0]) }
      it { expect(subject.values.map(&:bw3p).uniq).to eq([5.378, 4.971, 4.993, 5.001, 5.0]) }
    end
  end
end
