# frozen_string_literal: true

module HighPassFilterMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :hp, default: :oc2
    attribute :hpf2, default: :oc2
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
      p0.hp = high_pass_filter(:input, period: 14, previous: :hp).round(3)
      p0.hpf2 = hpf2(:input, period: 14, previous: :hpf2).round(3)
      p0.uhp1p = universal_one_pole_high_pass(:input, period: 14, previous: :uhp1p).round(3)

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

      it { expect(subject.values.map(&:uhp1p)).to eq([1.885, 3.627, 7.164, 14.271]) }
      it { expect(subject.values.map(&:hp)).to    eq([2.560, 4.370, 6.874, 11.564]) }
      it { expect(subject.values.map(&:hpf2)).to  eq([2.586, 4.217, 8.256, 16.665]) }

      it { expect(subject.values.map{ |m| m.hp2p.round(4) }).to  eq([0.2643, 0.8424, 0.8945, 1.7171]) }
      it { expect(subject.values.map{ |m| m.uhp2p.round(4) }).to eq([0.2636, 0.8421, 0.8941, 1.7165]) }
    end

    context "growing price" do
      let(:series) { Quant::Series.new(symbol: "HP", interval: "1d") }

      context "single-pole high-pass filter" do
        [[1, 0.853, 0.628],
         [2, 1.456, 1.209],
         [3, 1.562, 1.574],
         [4, 1.389, 1.803],
         [5, 1.094, 1.947],
         [6, 0.777, 2.038]].each do |n, expected, expected_universal|
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

      it { expect(subject.values.map(&:hp).uniq.take(5)).to eq([4.267, 3.641, 2.775, 1.909, 1.17]) }
      it { expect(subject.values.map(&:uhp1p).take(5)).to   eq([3.142, 1.974, 1.240, 0.779, 0.489]) }

      it { expect(subject.values.map{ |m| m.hp2p.round(4) }.take(5)).to  eq([0.4404, 0.0388, 0.0026, 0.0002, 0.0]) }
      it { expect(subject.values.map{ |m| m.uhp2p.round(4) }.take(5)).to eq([0.4394, 0.0386, 0.0026, 0.0002, 0.0]) }
    end
  end
end
