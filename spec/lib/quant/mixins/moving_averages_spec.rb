# frozen_string_literal: true

require "spec_helper"

module MixinTest
  class WeightedAverageTest < Quant::Indicators::IndicatorPoint
    attribute :wma, default: 0.0
    attribute :ewma, default: 0.0
  end

  class WeightedAverageIndicatorTest < Quant::Indicators::Indicator
    include Quant::Mixins::MovingAverages

    def points_class
      WeightedAverageTest
    end

    def compute
      p0.wma = weighted_moving_average(:input)
      p0.ewma = ewma(:input)
    end
  end

  class SimpleAverageTest < Quant::Indicators::IndicatorPoint
    attribute :sma, default: 0.0
  end

  class SimpleAverageIndicatorTest < Quant::Indicators::Indicator
    include Quant::Mixins::MovingAverages

    def points_class
      SimpleAverageTest
    end

    def compute
      p0.sma = simple_moving_average(:input, period: 3)
    end
  end

  class ExponentialAverageTest < Quant::Indicators::IndicatorPoint
    attribute :ema, default: :oc2
  end

  class ExponentialAverageIndicatorTest < Quant::Indicators::Indicator
    include Quant::Mixins::MovingAverages

    def points_class
      ExponentialAverageTest
    end

    def compute
      p0.ema = exponential_moving_average(:input, period: 3)
    end
  end

  RSpec.describe Quant::Mixins::MovingAverages do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename: filename, symbol: 'DEUCES', interval: "1d") }

    describe "Weighted Moving Average" do
      subject { WeightedAverageIndicatorTest.new(series: series, source: :oc2) }

      before { series.indicators.oc2.attach(indicator_class: WeightedAverageIndicatorTest, name: :wma) }

      context "deuces sample prices" do
        it { is_expected.to be_a(WeightedAverageIndicatorTest) }
        it { expect(subject.ticks.size).to eq(subject.series.size) }
        it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
        it { expect(subject.values.map(&:wma)).to eq([3.0, 4.2, 7.5, 14.7]) }
        it { expect(subject.values.map(&:ewma)).to eq([3.0, 3.75, 5.892857142857143, 10.714285714285714]) }
      end

      context "growing price" do
        let(:series) { Quant::Series.new(symbol: "WMA", interval: "1d") }

        [ [1, 1.0, 1.0],
          [2, 1.4, 1.25],
          [3, 2.1, 1.7142857142857142],
          [4, 3.0, 2.357142857142857],
          [5, 4.0, 3.142857142857143],
          [6, 5.0, 4.035714285714286]
        ].each do |n, expected_wma, expected_ewma|
          dataset = (1..n).to_a

          it "is #{expected_wma.inspect} when series: is #{dataset.inspect}" do
            dataset.each { |price| series << price }
            expect(subject.p0.wma).to eq expected_wma
          end

          it "is #{expected_ewma.inspect} when series: is #{dataset.inspect}" do
            dataset.each { |price| series << price }
            expect(subject.p0.ewma).to eq expected_ewma
          end
        end
      end

      context "static price" do
        let(:series) { Quant::Series.new(symbol: "WMA", interval: "1d") }

        before { 25.times { series << 5.0 } }

        it { expect(subject.ticks.size).to eq(subject.series.size) }
        it { expect(subject.values.map(&:input)).to be_all(5.0) }
        it { expect(subject.values.map(&:wma)).to be_all(5.0) }
        it { expect(subject.values.map(&:ewma)).to be_all(5.0) }
      end
    end

    describe "Simple Moving Average" do
      subject { SimpleAverageIndicatorTest.new(series: series, source: :oc2) }

      before { series.indicators.oc2.attach(indicator_class: SimpleAverageIndicatorTest, name: :sma) }

      context "deuces sample prices" do
        it { is_expected.to be_a(SimpleAverageIndicatorTest) }
        it { expect(subject.ticks.size).to eq(subject.series.size) }
        it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
        it { expect(subject.values.map(&:sma)).to eq([3.0, 4.5, 7.0, 14.0]) }
      end

      context "growing price" do
        let(:series) { Quant::Series.new(symbol: "SMA", interval: "1d") }

        [ [1, 1.0],
          [2, 1.5],
          [3, 2.0],
          [4, 3.0],
          [5, 4.0],
          [6, 5.0]
        ].each do |n, expected|
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

    describe "Exponential Moving Average" do
      subject { ExponentialAverageIndicatorTest.new(series: series, source: :oc2) }

      before { series.indicators.oc2.attach(indicator_class: ExponentialAverageIndicatorTest, name: :ema) }

      context "deuces sample prices" do
        it { is_expected.to be_a(ExponentialAverageIndicatorTest) }
        it { expect(subject.ticks.size).to eq(subject.series.size) }
        it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
        it { expect(subject.values.map(&:ema)).to eq([3.0, 4.5, 8.25, 16.125]) }
      end

      context "growing price" do
        let(:series) { Quant::Series.new(symbol: "EMA", interval: "1d") }

        [ [1, 1.0],
          [2, 1.5],
          [3, 2.25],
          [4, 3.125],
          [5, 4.0625],
          [6, 5.03125]
        ].each do |n, expected|
          dataset = (1..n).to_a

          it "is #{expected.inspect} when series: is #{dataset.inspect}" do
            dataset.each { |price| series << price }
            expect(subject.p0.ema).to eq expected
          end
        end
      end

      context "static price" do
        let(:series) { Quant::Series.new(symbol: "EMA", interval: "1d") }

        before { 25.times { series << 5.0 } }

        it { expect(subject.ticks.size).to eq(subject.series.size) }
        it { expect(subject.values.map(&:input)).to be_all(5.0) }
        it { expect(subject.values.map(&:ema)).to be_all(5.0) }
      end
    end
  end
end