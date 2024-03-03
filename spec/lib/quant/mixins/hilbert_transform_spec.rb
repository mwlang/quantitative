# frozen_string_literal: true

require "spec_helper"

module HilbertMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :ht, default: 0.0
  end

  class TestIndicator < Quant::Indicators::Indicator
    include Quant::Mixins::HilbertTransform

    def points_class
      TestPoint
    end

    def compute
      p0.ht = hilbert_transform(:input, period: 3).round(3)
    end
  end

  RSpec.describe Quant::Mixins::HilbertTransform do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }

    subject { TestIndicator.new(series:, source: :oc2) }

    before { series.indicators.oc2.attach(indicator_class: TestIndicator, name: :hilbert) }

    context "deuces sample prices" do
      it { is_expected.to be_a(TestIndicator) }
      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
      it { expect(subject.values.map(&:ht)).to eq([0.0, 0.221, 0.662, 2.869]) }
    end

    context "growing price" do
      let(:series) { Quant::Series.new(symbol: "HT", interval: "1d") }

      [[1, 0.0],
       [2, 0.074],
       [3, 0.147],
       [4, 0.662],
       [5, 1.177],
       [6, 1.251]].each do |n, expected|
        dataset = (1..n).to_a

        it "is #{expected.inspect} when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.ht).to eq expected
        end
      end
    end

    context "static price" do
      using Quant

      let(:series) { Quant::Series.new(symbol: "HT", interval: "1d") }

      before { 25.times { series << 5.0 } }

      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to be_all(5.0) }
      it { expect(subject.values.map(&:ht).uniq).to eq([0.0]) }
    end
  end
end
