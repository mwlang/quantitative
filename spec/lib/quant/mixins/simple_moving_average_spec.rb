# frozen_string_literal: true

require "spec_helper"

module SmaMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :sma, default: 0.0
  end

  class TestIndicator < Quant::Indicators::Indicator
    include Quant::Mixins::MovingAverages

    def points_class
      TestPoint
    end

    def compute
      p0.sma = simple_moving_average(:input, period: 3)
    end
  end

  RSpec.describe Quant::Mixins::SimpleMovingAverage do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }

    subject { TestIndicator.new(series:, source: :oc2) }

    before { series.indicators.oc2.attach(indicator_class: TestIndicator, name: :sma) }

    context "deuces sample prices" do
      it { is_expected.to be_a(TestIndicator) }
      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
      it { expect(subject.values.map(&:sma)).to eq([3.0, 4.5, 7.0, 14.0]) }
    end

    context "growing price" do
      let(:series) { Quant::Series.new(symbol: "SMA", interval: "1d") }

      [[1, 1.0],
       [2, 1.5],
       [3, 2.0],
       [4, 3.0],
       [5, 4.0],
       [6, 5.0]].each do |n, expected|
        dataset = (1..n).to_a

        it "is #{expected.inspect} when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.sma).to eq expected
        end
      end
    end

    context "static price" do
      let(:series) { Quant::Series.new(symbol: "SMA", interval: "1d") }

      before { 25.times { series << 5.0 } }

      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to be_all(5.0) }
      it { expect(subject.values.map(&:sma)).to be_all(5.0) }
    end
  end
end
