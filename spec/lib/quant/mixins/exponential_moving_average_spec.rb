# frozen_string_literal: true

module EmaMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :ema, default: :oc2
  end

  class TestIndicator < Quant::Indicators::Indicator
    include Quant::Mixins::MovingAverages

    def points_class
      TestPoint
    end

    def compute
      p0.ema = exponential_moving_average(:input, period: 3)
    end
  end

  RSpec.describe Quant::Mixins::ExponentialMovingAverage do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }

    subject { TestIndicator.new(series:, source: :oc2) }

    before { series.indicators.oc2.attach(indicator_class: TestIndicator, name: :ema) }

    context "deuces sample prices" do
      it { is_expected.to be_a(TestIndicator) }
      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
      it { expect(subject.values.map(&:ema)).to eq([3.0, 4.5, 8.25, 16.125]) }
    end

    context "growing price" do
      let(:series) { Quant::Series.new(symbol: "EMA", interval: "1d") }

      [[1, 1.0],
       [2, 1.5],
       [3, 2.25],
       [4, 3.125],
       [5, 4.0625],
       [6, 5.03125]].each do |n, expected|
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
