# frozen_string_literal: true

require "spec_helper"

module HighPassFilterMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :hp, default: :oc2
    attribute :hp2p, default: :oc2
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

      p0.hp2p = two_pole_high_pass_filter(:input, period: 3, previous: :hp2p)
      p0.uhp2p = universal_two_pole_high_pass(:input, period: 3, previous: :uhp2p)
    end
  end

  RSpec.describe Quant::Mixins::HighPassFilters do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }

    subject { TestIndicator.new(series:, source: :oc2) }

    before { series.indicators.oc2.attach(indicator_class: TestIndicator, name: :hilbert) }

    context "deuces sample prices" do
      it { is_expected.to be_a(TestIndicator) }
      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }

      it { expect(subject.values.map(&:hp)).to    eq([-0.033, 1.648, 2.437, 5.688]) }
      it { expect(subject.values.map(&:uhp1p)).to eq([-0.804, 1.314, 1.844, 3.898]) }

      it { expect(subject.values.map{ |m| m.hp2p.round(4) }).to  eq([0.2643, 0.8424, 0.8945, 1.7171]) }
      it { expect(subject.values.map{ |m| m.uhp2p.round(4) }).to eq([0.2636, 0.8421, 0.8941, 1.7165]) }
    end

    context "growing price" do
      let(:series) { Quant::Series.new(symbol: "HP", interval: "1d") }

      context "single-pole high-pass filter" do
        [[1, -0.011, -0.268],
         [2, 0.549, 0.438],
         [3, 0.539, 0.249],
         [4, 0.942, 0.299],
         [5, 1.009, 0.286],
         [6, 1.337, 0.289]].each do |n, expected, expected_universal|
          dataset = (1..n).to_a

          it "is #{expected.inspect} for :hp when series: is #{dataset.inspect}" do
            dataset.each { |price| series << price }
            expect(subject.p0.hp).to eq expected
          end

          it "is #{expected_universal.inspect} for :uhp1p when series: is #{dataset.inspect}" do
            dataset.each { |price| series << price }
            expect(subject.p0.uhp1p).to eq expected_universal
          end
        end
      end

      context "two-pole high-pass filter" do
        [[1, 0.0881, 0.0879],
         [2, 0.2808, 0.2807],
         [3, 0.0251, 0.0251],
         [4, 0.0017, 0.0017],
         [5, 0.0001, 0.0001],
         [6, 0.0, 0.0]].each do |n, expected, expected_universal|
          dataset = (1..n).to_a

          it "is #{expected.inspect} for :hp2p when series: is #{dataset.inspect}" do
            dataset.each { |price| series << price }
            expect(subject.p0.hp2p.round(4)).to eq expected
          end

          it "is #{expected_universal.inspect} for :uhp2p when series: is #{dataset.inspect}" do
            dataset.each { |price| series << price }
            expect(subject.p0.uhp2p.round(4)).to eq expected_universal
          end
        end
      end
    end

    context "static price" do
      using Quant

      let(:series) { Quant::Series.new(symbol: "HT", interval: "1d") }

      before { 25.times { series << 5.0 } }

      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to be_all(5.0) }

      it { expect(subject.values.map(&:hp).uniq.take(5)).to eq([-0.055, 1.381, 0.655, 1.34, 0.833]) }
      it { expect(subject.values.map(&:uhp1p).take(5)).to eq([-1.34, 0.359, -0.096, 0.026, -0.007]) }

      it { expect(subject.values.map{ |m| m.hp2p.round(4) }.take(5)).to  eq([0.4404, 0.0388, 0.0026, 0.0002, 0.0]) }
      it { expect(subject.values.map{ |m| m.uhp2p.round(4) }.take(5)).to eq([0.4394, 0.0386, 0.0026, 0.0002, 0.0]) }
    end
  end
end
