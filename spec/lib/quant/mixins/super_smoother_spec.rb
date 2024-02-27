# frozen_string_literal: true

require "spec_helper"

module SuperSmootherMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    # attribute :ss, default: :oc2
    attribute :ss3p, default: :oc2
    attribute :ss2p, default: :oc2
  end

  class TestIndicator < Quant::Indicators::Indicator
    include Quant::Mixins::SuperSmoother

    def points_class
      TestPoint
    end

    def compute
      p0.ss3p = three_pole_super_smooth(:input, period: 3, previous: :ss3p).round(3)
      p0.ss2p = two_pole_super_smooth(:input, period: 3, previous: :ss2p).round(3)
    end
  end

  RSpec.describe Quant::Mixins::SuperSmoother do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }

    describe "#super_smoother" do
      subject { TestIndicator.new(series:, source: :oc2) }

      before { series.indicators.oc2.attach(indicator_class: TestIndicator, name: :ss) }

      context "deuces sample prices" do
        it { is_expected.to be_a(TestIndicator) }
        it { expect(subject.ticks.size).to eq(subject.series.size) }
        it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
        it { expect(subject.values.map(&:ss2p)).to eq([3.0, 4.516, 9.065, 18.226]) }
        it { expect(subject.values.map(&:ss3p)).to eq([3.0, 6.399, 13.041, 25.984]) }
      end

      context "growing price" do
        let(:series) { Quant::Series.new(symbol: "SS", interval: "1d") }

        [[1, 1.0, 1.0],
         [2, 1.505, 2.133],
         [3, 2.516, 3.214],
         [4, 3.548, 4.182],
         [5, 4.574, 5.177],
         [6, 5.575, 6.181]].each do |n, expected_ss2p, expected_ss3p|
          dataset = (1..n).to_a

          it "is #{expected_ss2p.inspect} when series: is #{dataset.inspect}" do
            dataset.each { |price| series << price }
            expect(subject.p0.ss2p).to eq expected_ss2p
          end

          it "is #{expected_ss3p.inspect} when series: is #{dataset.inspect}" do
            dataset.each { |price| series << price }
            expect(subject.p0.ss3p).to eq expected_ss3p
          end
        end
      end

      context "static price" do
        let(:series) { Quant::Series.new(symbol: "SS", interval: "1d") }

        before { 25.times { series << 5.0 } }

        it { expect(subject.ticks.size).to eq(subject.series.size) }
        it { expect(subject.values.map(&:input)).to be_all(5.0) }
        it { expect(subject.values.map(&:ss3p)).to be_all(5.0) }
      end
    end
  end
end
