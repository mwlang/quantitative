# frozen_string_literal: true

module WmaMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :wma, default: 0.0
    attribute :ewma, default: 0.0
  end

  class TestIndicator < Quant::Indicators::Indicator
    include Quant::Mixins::WeightedMovingAverage

    def points_class
      TestPoint
    end

    def compute
      p0.wma = weighted_moving_average(:input)
      p0.ewma = ewma(:input)
    end
  end

  RSpec.describe Quant::Mixins::WeightedMovingAverage do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }

    subject { TestIndicator.new(series:, source: :oc2) }

    before { series.indicators.oc2.attach(indicator_class: TestIndicator, name: :wma) }

    context "deuces sample prices" do
      it { is_expected.to be_a(TestIndicator) }
      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
      it { expect(subject.values.map(&:wma)).to eq([3.0, 4.2, 7.5, 14.7]) }
      it { expect(subject.values.map(&:ewma)).to eq([3.0, 3.75, 5.892857142857143, 10.714285714285714]) }
    end

    context "growing price" do
      let(:series) { Quant::Series.new(symbol: "WMA", interval: "1d") }

      [[1, 1.0, 1.0],
       [2, 1.4, 1.25],
       [3, 2.1, 1.7142857142857142],
       [4, 3.0, 2.357142857142857],
       [5, 4.0, 3.142857142857143],
       [6, 5.0, 4.035714285714286]].each do |n, expected_wma, expected_ewma|
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
end
