# frozen_string_literal: true

require "spec_helper"

module StochasticMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :st, default: 0.0
  end

  class TestIndicator < Quant::Indicators::Indicator
    include Quant::Mixins::Stochastic

    def points_class
      TestPoint
    end

    def compute
      p0.st = stochastic(:input, period: 12).round(3)
    end
  end

  RSpec.describe Quant::Mixins::Stochastic do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }

    subject { TestIndicator.new(series:, source: :oc2) }

    before { series.indicators.oc2.attach(indicator_class: TestIndicator, name: :stoch) }

    context "deuces sample prices" do
      it { is_expected.to be_a(TestIndicator) }
      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
      it { expect(subject.values.map(&:st)).to eq([0.0, 100.0, 100.0, 100.0]) }
    end

    context "growing price" do
      let(:series) { Quant::Series.new(symbol: "ST", interval: "1d") }

      [[1, 0.0],
       [2, 100],
       [3, 100],
       [4, 100],
       [5, 100],
       [6, 100],
      ].each do |n, expected|
        dataset = (1..n).to_a

        it "is #{expected.inspect} when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.st).to eq expected
        end
      end
    end

    context "random" do
      let(:series) { Quant::Series.new(symbol: "ST", interval: "1d") }

      it "climbs and falls with series" do
        [36, 32, 69, 47, 28, 30, 37, 39, 45].map { |price| series << price }
        expect(subject.values.map(&:st)).to eq([0.0, 0.0, 100.0, 40.541, 0.0, 4.878, 21.951, 26.829, 41.463])
      end
    end
    context "static price" do
      using Quant

      let(:series) { Quant::Series.new(symbol: "ST", interval: "1d") }

      before { 25.times { series << 5.0 } }

      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to be_all(5.0) }
      it { expect(subject.values.map(&:st).uniq).to eq([0.0]) }
    end
  end
end
