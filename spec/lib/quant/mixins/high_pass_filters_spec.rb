# frozen_string_literal: true

require "spec_helper"

module HighPassFilterMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :hp, default: :oc2
    attribute :uhp1p, default: :oc2
    attribute :uhp2p, default: :oc2
  end

  class TestIndicator < Quant::Indicators::Indicator
    include Quant::Mixins::HighPassFilters

    def points_class
      TestPoint
    end

    def compute
      p0.hp = high_pass_filter(:input, period: 3).round(3)
      p0.uhp1p = universal_one_pole_high_pass(:input, period: 3, previous: :uhp1p).round(3)
      p0.uhp2p = universal_two_pole_high_pass(:input, period: 3, previous: :uhp2p).round(3)
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
      it { expect(subject.values.map(&:hp)).to eq([3.0, 0.787, 0.696, 1.626]) }
      it { expect(subject.values.map(&:uhp1p)).to eq([-0.804, 1.314, 1.844, 3.898]) }
      it { expect(subject.values.map(&:uhp2p)).to eq([0.264, 0.842, 0.894, 1.717]) }
    end

    context "growing price" do
      let(:series) { Quant::Series.new(symbol: "HT", interval: "1d") }

      [[1, 1.0, -0.268, 0.088],
       [2, 0.262, 0.438, 0.281],
       [3, -0.041, 0.249, 0.025],
       [4, -0.015, 0.299, 0.002],
       [5, 0.002, 0.286, 0.0],
       [6, 0.001, 0.289, 0.0]].each do |n, expected, expected_uhp1p, expected_uhp2p|
        dataset = (1..n).to_a

        it "is #{expected.inspect} for :hp when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.hp).to eq expected
        end

        it "is #{expected_uhp1p.inspect} for :uhp1p when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.uhp1p).to eq expected_uhp1p
        end

        it "is #{expected_uhp2p.inspect} for :uhp1p when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.uhp2p).to eq expected_uhp2p
        end
      end
    end

    context "static price" do
      using Quant

      let(:series) { Quant::Series.new(symbol: "HT", interval: "1d") }

      before { 25.times { series << 5.0 } }

      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to be_all(5.0) }
      it { expect(subject.values.map(&:hp).uniq).to eq([5.0, -0.055, -0.261, -0.008, 0.013, 0.001, -0.001, -0.0]) }
      it { expect(subject.values.map(&:uhp1p).uniq).to eq([-1.34, 0.359, -0.096, 0.026, -0.007, 0.002, -0.001, 0.0]) }
      it { expect(subject.values.map(&:uhp2p).uniq).to eq([0.439, 0.039, 0.003, 0.0]) }
    end
  end
end
