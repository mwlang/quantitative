# frozen_string_literal: true

require "spec_helper"

module FishertMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :ft, default: 0.0
    attribute :rft, default: 0.0
    attribute :ift, default: 0.0
  end

  class TestIndicator < Quant::Indicators::Indicator
    include Quant::Mixins::FisherTransform

    def points_class
      TestPoint
    end

    def compute
      scaled_input = p0.input / 25.0
      p0.ft = fisher_transform(scaled_input).round(3)
      p0.rft = relative_fisher_transform(p0.input, max_value: 50.0).round(3)
      p0.ift = inverse_fisher_transform(scaled_input, scale_factor: 1.0).round(3)
    end
  end

  RSpec.describe Quant::Mixins::FisherTransform do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }

    subject { TestIndicator.new(series:, source: :oc2) }

    before { series.indicators.oc2.attach(indicator_class: TestIndicator, name: :fisher) }

    context "deuces sample prices" do
      it { is_expected.to be_a(TestIndicator) }
      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
      it { expect(subject.values.map(&:ft)).to eq([0.121, 0.245, 0.523, 1.946]) }
      it { expect(subject.values.map(&:rft)).to eq([0.06, 0.121, 0.245, 0.523]) }
      it { expect(subject.values.map(&:ift)).to eq([0.119, 0.235, 0.446, 0.744]) }
    end

    context "growing price" do
      let(:series) { Quant::Series.new(symbol: "FISHER", interval: "1d") }

      it "raises domain errors" do
        allow(Math).to receive(:log).and_raise(Math::DomainError)
        series << 1
        expect{ subject.p0.ft }.to raise_error(Math::DomainError)
      end

      [[1, 0.040, 0.020, 0.040],
       [2, 0.080, 0.040, 0.080],
       [3, 0.121, 0.060, 0.119],
       [4, 0.161, 0.080, 0.159],
       [5, 0.203, 0.100, 0.197],
       [6, 0.245, 0.121, 0.235]].each do |n, ft_expected, rft_expected, ift_expected|
        dataset = (1..n).to_a

        it "is #{ft_expected.inspect} for fisher when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.ft).to eq ft_expected
        end

        it "is #{rft_expected.inspect} for relative fisher when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.rft).to eq rft_expected
        end

        it "is #{ift_expected.inspect} for inverse fisher when series: is #{dataset.inspect}" do
          dataset.each { |price| series << price }
          expect(subject.p0.ift).to eq ift_expected
        end
      end
    end

    context "static price" do
      using Quant

      let(:series) { Quant::Series.new(symbol: "FISHER", interval: "1d") }

      before { 5.times {|i| series << i + 15 } }

      it { expect(subject.ticks.size).to eq(subject.series.size) }
      it { expect(subject.values.map(&:input)).to eq([15.0, 16.0, 17.0, 18.0, 19.0]) }
      it { expect(subject.values.map(&:ft).uniq).to eq([0.693, 0.758, 0.829, 0.908, 0.996]) }
      it { expect(subject.values.map(&:rft).uniq).to eq([0.31, 0.332, 0.354, 0.377, 0.4]) }
      it { expect(subject.values.map(&:ift).uniq).to eq([0.537, 0.565, 0.592, 0.617, 0.641]) }
    end
  end
end
