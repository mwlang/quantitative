# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Series do
  let(:series_fixture_path) { fixture_path("series") }
  let(:appl) { "AAPL" }
  let(:ibm) { "IBM" }
  let(:apple_fixture_filename) { fixture_filename("AAPL-19990104_19990107.txt", :series) }
  let(:ibm_fixture_filename) { fixture_filename("IBM-19990104_19990107.txt", :series) }

  describe ".from_file" do
    subject { described_class.from_file(filename: filename, symbol: symbol, interval: "1d") }

    context "valid" do
      let(:filename) { apple_fixture_filename }
      let(:symbol) { appl }

      it { is_expected.to be_a(described_class) }
      it { expect(subject.ticks.size).to eq(4) }
      it { expect(subject.size).to eq(4) }
    end

    context "invalid" do
      let(:filename) { "invalid" }
      let(:symbol) { appl }

      it { expect{ subject }.to raise_error(RuntimeError, /File invalid does not exist/) }
    end
  end

  describe ".from_json" do
    let(:symbol) { appl }
    let(:apple_json_fixture_filename) { fixture_filename("AAPL-19990104_19990107.json", :series) }
    let(:json) { File.read(apple_json_fixture_filename) }

    subject { described_class.from_json(symbol: symbol, interval: "1d", json: json) }

    it { is_expected.to be_a(described_class) }
    it { expect(subject.ticks.size).to eq(4) }
  end

  describe "equality" do
    let(:ema0) { 0.372209817171097 }
    let(:ema1) { 0.3725514716031602 }
    let(:ema2) { 0.37299306596978826 }
    let(:ema3) { 0.3736671823762353 }

    xcontext "when the same" do
      let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
      let(:series2) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }

      it { expect(series1).to eq series2 }
    end

    context "when duplicated" do
      let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
      let(:series2) { series1.dup }

      it "is equal but not the same" do
        expect(series1).to eq series2
        expect(series1).not_to be series2
      end

      it "has the same ticks across different series same objects" do
        expect(series2.ticks.size).to eq(4)
        expect(series2.ticks.first).to eq series1.ticks.first
        expect(series2.ticks.first.series).to eq series1.ticks.first.series
        expect(series2.ticks.first.series).to be series1.ticks.first.series
      end

      xit "shares indicators across two series" do
        expect(series2.indicators).to eq series1.indicators
      end

      xit "indicators computed against the parent series" do
        expect(series1.ticks.count).to eq 4
        expect(series1.indicators.ma.count).to eq 4
        expect(series2.indicators.ma.count).to eq 4
      end

      xit "indicators computed against the parent series" do
        expect(series2.indicators.ma.count).to eq 4
        expect(series1.indicators.ma.count).to eq 4
      end

      it "has full date range for series1" do
        expect(series1.ticks.count).to eq 4
        expect(series1.ticks.first.close_timestamp).to eq Time.local(1999, 1, 4, 16)
        expect(series1.ticks.last.close_timestamp).to eq Time.local(1999, 1, 7, 16)
      end

      xit "has full indicators for series1" do
        expect(series1.indicators.ma.count).to eq 4
        expect(series1.indicators.ma.first.ema).to eq ema0
        expect(series1.indicators.ma.last.ema).to eq ema3
      end

      it "has full date range for series2" do
        expect(series2.ticks.count).to eq 4
        expect(series2.ticks.first.close_timestamp).to eq Time.local(1999, 1, 4, 16)
        expect(series2.ticks.last.close_timestamp).to eq Time.local(1999, 1, 7, 16)
      end

      xit "has full indicator for series2" do
        expect(series2.indicators.ma.count).to eq 4
        expect(series2.indicators.ma[0].ema).to eq ema0
        expect(series2.indicators.ma[1].ema).to eq ema1
        expect(series2.indicators.ma[2].ema).to eq ema2
        expect(series2.indicators.ma[3].ema).to eq ema3
      end
    end

    context "when limited" do
      let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
      let(:period) { (series1.ticks[1].open_timestamp..series1.ticks[2].close_timestamp) }
      let(:series2) { series1.limit(period) }

      it "has full date range for series1" do
        expect(series1.ticks.count).to eq 4
        expect(series1.ticks.first.close_timestamp).to eq Time.local(1999, 1, 4, 16)
        expect(series1.ticks.last.close_timestamp).to eq Time.local(1999, 1, 7, 16)
      end

      xit "it limits the indicators to the subset of ticks" do
        expect(series1.indicators.ma.count).to eq 4
        expect(series1.indicators.ma[0].ema).to eq ema0
        expect(series1.indicators.ma[1].ema).to eq ema1
        expect(series1.indicators.ma[2].ema).to eq ema2
        expect(series1.indicators.ma[3].ema).to eq ema3
      end

      it "has shorter date range for series2" do
        expect(series2.ticks.count).to eq 2
        expect(series2.ticks.first.close_timestamp).to eq Time.local(1999, 1, 5, 16)
        expect(series2.ticks.last.close_timestamp).to eq Time.local(1999, 1, 6, 16)
        expect(series2.ticks[0]).to eq series1.ticks[1]
        expect(series2.ticks[1]).to eq series1.ticks[2]
      end

      xit "has fewer indicators for series2" do
        expect(series2.indicators.ma.count).to eq 2
        expect(series2.indicators.ma.count).to eq 2
        expect(series2.indicators.ma[0].ema).to eq ema1
        expect(series2.indicators.ma[1].ema).to eq ema2
      end
    end
  end

  describe "#highest" do
    let(:series) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
    let(:high_prices) { series.ticks.map(&:high_price) }

    subject { series.highest }

    it { is_expected.to be_a(Quant::Ticks::OHLC) }
    it { expect(subject.high_price).to eq(high_prices.max) }
  end

  describe "#lowest" do
    let(:series) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
    let(:low_prices) { series.ticks.map(&:low_price) }

    subject { series.lowest }

    it { is_expected.to be_a(Quant::Ticks::OHLC) }
    it { expect(subject.low_price).to eq(low_prices.min) }
  end

  describe "#limit" do
    let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }

    subject { series1.limit(period) }

    context "fully covers" do
      let(:period) { (series1.ticks.first.close_timestamp..series1.ticks.last.close_timestamp) }

      it { is_expected.to eq series1 }
    end

    context "partially covers" do
      let(:period) { (series1.ticks.first.close_timestamp..series1.ticks[2].close_timestamp) }

      it { is_expected.to be_a(described_class) }
      it { expect(subject.ticks.size).to eq(3) }
      it { expect(subject.limit(period)).to eq subject }
    end
  end

  describe "#limit_iterations" do
    let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }

    subject { series1.limit_iterations(start_iteration, stop_iteration) }

    context "fully covers" do
      let(:start_iteration) { 0 }
      let(:stop_iteration) { 3 }

      it { is_expected.to eq series1 }
      it { expect(subject.ticks.size).to eq(4) }
    end

    context "partially covers, skipping 1st iteration" do
      let(:start_iteration) { 1 }
      let(:stop_iteration) { 3 }

      it { is_expected.to be_a(described_class) }
      it { expect(subject.ticks.size).to eq(3) }
    end

    context "partially covers dropping last iteration" do
      let(:start_iteration) { 0 }
      let(:stop_iteration) { 2 }

      it { is_expected.to be_a(described_class) }
      it { expect(subject.ticks.size).to eq(3) }
    end
  end

  describe "#select!" do
    let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
    let(:series2) { described_class.from_file(filename: ibm_fixture_filename, symbol: ibm, interval: "1d") }
    let(:tick) { series1.ticks[2] }

    subject { series1.select! { |t| t == tick } }

    it { expect{ subject }.to change{ series1.ticks.size }.from(4).to(1) }

    context "series to series" do
      subject { series1.select! { |tick| series2.any? { |other| tick.corresponding?(other) } } }

      it { expect{ subject }.not_to change{ series1.ticks.size }.from(4) }

      context "when series2 is shorter" do
        before { series2.ticks.pop(2) }

        it { expect{ subject }.to change{ series1.ticks.size }.from(4).to(2) }
      end
    end
  end
end
