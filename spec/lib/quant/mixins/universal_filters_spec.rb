# frozen_string_literal: true

require "spec_helper"

module UniversalMixinTest
  class TestPoint < Quant::Indicators::IndicatorPoint
    attribute :ema, default: :oc2
    attribute :uema, default: :oc2
    attribute :u1plp, default: :oc2
    attribute :u2plp, default: :oc2
    attribute :u1php, default: :oc2
    attribute :u2php, default: :oc2
    attribute :ubp, default: :oc2
  end

  class TestIndicator < Quant::Indicators::Indicator
    include Quant::Mixins::UniversalFilters

    def points_class
      TestPoint
    end

    def compute
      p0.ema = exponential_moving_average(:input, period: 3, previous: :ema).round(3)
      p0.uema = universal_ema(:input, period: 3, previous: :uema).round(3)
      p0.u1plp = universal_one_pole_low_pass(:input, period: 3, previous: :u1plp).round(3)
      p0.u2plp = universal_two_pole_low_pass(:input, period: 3, previous: :u2plp).round(3)
      p0.u1php = universal_one_pole_high_pass(:input, period: 3, previous: :u1php).round(3)
      p0.u2php = universal_two_pole_high_pass(:input, period: 3, previous: :u2php).round(3)
      p0.ubp = universal_band_pass(:input, period: 3, previous: :ubp).round(3)
    end
  end

  RSpec.describe Quant::Mixins::UniversalFilters do
    let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
    let(:deuces_series) { Quant::Series.from_file(filename:, symbol: "DEUCES", interval: "1d") }
    let(:constant_series) do
      Quant::Series.new(symbol: "FIVES", interval: "1d").tap{ |s| 10.times { s << 5.0 } }
    end

    subject { TestIndicator.new(series:, source: :oc2) }

    before { series.indicators.oc2.attach(indicator_class: TestIndicator, name: :universal) }

    describe "#universal_ema" do
      context "deuces series" do
        let(:series) { deuces_series }
        let(:expected) { [3.0, 4.5, 8.25, 16.125] }

        it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
        it { expect(subject.values.map(&:ema)).to eq(expected) }
        it { expect(subject.values.map(&:uema)).to eq(expected) }
      end

      context "constant series" do
        let(:series) { constant_series }

        it { expect(subject.values.map(&:ema).uniq).to eq([5.0]) }
        it { expect(subject.values.map(&:uema).uniq).to eq([5.0]) }
      end
    end

    context "#universal_one_pole_low_pass" do
      context "deuces series" do
        let(:series) { deuces_series }
        let(:expected) { [3.0, 6.804, 13.392, 26.842] }

        it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
        it { expect(subject.values.map(&:u1plp)).to eq(expected) }
      end

      context "constant series" do
        let(:series) { constant_series }

        it { expect(subject.values.map(&:input)).to be_all(5.0) }
        it { expect(subject.values.map(&:u1plp).uniq).to eq([5.0]) }
      end
    end

    context "#universal_two_pole_low_pass" do
      context "deuces series" do
        let(:series) { deuces_series }
        let(:expected) { [3.0, 13.099, 16.436, 44.223] }

        it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
        it { expect(subject.values.map(&:u2plp)).to eq(expected) }
      end

      context "constant series" do
        let(:series) { constant_series }

        it { expect(subject.values.map(&:input)).to be_all(5.0) }
        it { expect(subject.values.map(&:u2plp).uniq).to eq([5.0]) }
      end
    end

    context "#universal_one_pole_high_pass" do
      context "deuces series" do
        let(:series) { deuces_series }
        let(:expected) { [-0.804, 1.314, 1.844, 3.898] }

        it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
        it { expect(subject.values.map(&:u1php)).to eq(expected) }
      end

      context "constant series" do
        let(:series) { constant_series }
        let(:expected) { [-1.34, 0.359, -0.096, 0.026, -0.007, 0.002, -0.001, 0.0] }

        it { expect(subject.values.map(&:input)).to be_all(5.0) }
        it { expect(subject.values.map(&:u1php).uniq).to eq(expected) }
      end
    end

    context "#universal_two_pole_high_pass" do
      context "deuces series" do
        let(:series) { deuces_series }
        let(:expected) { [0.264, 0.842, 0.894, 1.717] }

        it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
        it { expect(subject.values.map(&:u2php)).to eq(expected) }
      end

      context "constant series" do
        let(:series) { constant_series }
        let(:expected) { [0.439, 0.039, 0.003, 0.0] }

        it { expect(subject.values.map(&:input)).to be_all(5.0) }
        it { expect(subject.values.map(&:u2php).uniq).to eq(expected) }
      end
    end

    context "#universal_band_pass" do
      context "deuces series" do
        let(:series) { deuces_series }
        let(:expected) { [-5.97, 18.978, -109.578, 740.42] }

        it { expect(subject.values.map(&:input)).to eq([3.0, 6.0, 12.0, 24.0]) }
        it { expect(subject.values.map(&:ubp)).to eq(expected) }
      end

      context "constant series" do
        let(:series) { constant_series }
        let(:expected) { [-9.95, 19.8, -150.429, 934.648, -5909.459] }

        it { expect(subject.values.map(&:input)).to be_all(5.0) }
        it { expect(subject.values.map(&:ubp).slice(0, 5)).to eq(expected) }
      end
    end
  end
end
