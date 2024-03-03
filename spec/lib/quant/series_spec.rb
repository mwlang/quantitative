# frozen_string_literal: true

require "spec_helper"

RSpec::Matchers.define :match_hash do |expected|
  match do |actual|
    @mismatch = match_hash_recursive(expected, actual)
    @mismatch.nil?
  end

  failure_message do |actual|
    "expected that #{actual} would match #{expected}, but #{@mismatch}"
  end

  def match_hash_recursive(expected, actual, path = [])
    return "expected a Hash, got #{actual.class}" unless actual.is_a?(Hash)
    return "missing keys: #{(expected.keys - actual.keys).join(', ')} at #{path.join('.')}" unless (expected.keys - actual.keys).empty?
    return "extra keys: #{(actual.keys - expected.keys).join(', ')} at #{path.join('.')}" unless (actual.keys - expected.keys).empty?

    expected.each do |key, value|
      new_path = path + [key]
      if value.is_a?(Hash)
        mismatch = match_hash_recursive(value, actual[key], new_path)
        return mismatch unless mismatch.nil?
      elsif !actual[key].is_a?(value)
        return "expected a #{value}, got #{actual[key].class} at #{new_path.join('.')}"
      end
    rescue StandardError
      return "expected a #{value}, got #{actual[key].class} at #{new_path.join('.')}"
    end

    nil
  end
end

RSpec.describe Quant::Series do
  let(:open_timestamp) { Quant.current_time - 60 }
  let(:close_timestamp) { Quant.current_time }
  let(:appl) { "AAPL" }
  let(:ibm) { "IBM" }
  let(:apple_fixture_filename) { fixture_filename("AAPL-19990104_19990107.txt", :series) }
  let(:ibm_fixture_filename) { fixture_filename("IBM-19990104_19990107.txt", :series) }

  describe ".from_file" do
    subject { described_class.from_file(filename:, symbol:, interval: "1d") }

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
    let(:expected_hash) do
      { "interval" => String, "symbol" => String, "ticks" => Array }
    end
    subject { described_class.from_json(symbol:, interval: "1d", json:) }

    it { is_expected.to be_a(described_class) }
    it { expect(subject.ticks.size).to eq(4) }
    it { expect(subject.to_h).to match_hash(expected_hash) }
    it { expect(Oj.load(subject.to_json)).to match_hash(expected_hash) }
  end

  describe "#<<" do
    let(:series) { described_class.new(symbol: appl, interval: "1d") }

    subject { series << tick }

    context "when Ticks::Tick::OHLC" do
      let(:tick) do
        Quant::Ticks::OHLC.new \
          close_timestamp:,
          open_timestamp:,
          open_price: 10,
          high_price: 20,
          low_price: 5,
          close_price: 15
      end

      it { expect{ subject }.to change{ series.ticks.size }.from(0).to(1) }
      it { expect(subject.first.open_price).to eq(10) }
      it { expect(subject.first.close_price).to eq(15) }
      it { expect(subject.highest.high_price).to eq(20) }
    end

    context "when Ticks::Tick::Spot" do
      let(:tick) { Quant::Ticks::Spot.new(timestamp: close_timestamp, price: 15) }

      it { expect{ subject }.to change{ series.ticks.size }.from(0).to(1) }
      it { expect(subject.first.price).to eq(15) }
      it { expect(tick.high_price).to eq(15) }
      it { expect(subject.highest.high_price).to eq(15) }
    end

    context "when Integer" do
      let(:tick) { 15 }

      it { expect{ subject }.to change{ series.ticks.size }.from(0).to(1) }
      it { expect(subject.first.price).to eq(15) }
      it { expect(subject.highest.high_price).to eq(15) }
    end

    context "when Float" do
      let(:tick) { 15.0 }

      it { expect{ subject }.to change{ series.ticks.size }.from(0).to(1) }
      it { expect(subject.first.price).to eq(15.0) }
      it { expect(subject.highest.high_price).to eq(15.0) }
    end

    context "when Rational" do
      let(:tick) { 15.0r }

      it { expect{ subject }.to change{ series.ticks.size }.from(0).to(1) }
      it { expect(subject.first.price).to eq(15.0r) }
      it { expect(subject.highest.high_price).to eq(15.0r) }
    end
  end

  describe "equality" do
    context "when the same" do
      let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
      let(:series2) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }

      it { expect(series1).to eq series2 }
    end

    context "when the different" do
      context "when symbol is different" do
        let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
        let(:series2) { described_class.from_file(filename: apple_fixture_filename, symbol: ibm, interval: "1d") }

        it { expect(series1).not_to eq series2 }
      end

      context "when interval is different" do
        let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
        let(:series2) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1m") }

        it { expect(series1).not_to eq series2 }
      end

      context "when ticks are different" do
        let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
        let(:series2) { described_class.from_file(filename: ibm_fixture_filename, symbol: ibm, interval: "1d") }

        it { expect(series1).not_to eq series2 }
      end
    end

    context "when duplicated" do
      let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
      let(:series1) { described_class.from_file(filename:, symbol: "DEUCES", interval: "1d") }
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

      it "indicators computed against the parent series" do
        expect(series1.ticks.count).to eq 4
        expect(series1.indicators.oc2.ping.count).to eq 4
        expect(series2.indicators.oc2.ping.count).to eq 4
      end

      it "indicators computed against the parent series" do
        expect(series2.indicators.oc2.ping.count).to eq 4
        expect(series1.indicators.oc2.ping.count).to eq 4
      end

      it "has full date range for series1" do
        expect(series1.ticks.count).to eq 4
        expect(series1.ticks.first.close_timestamp).to eq Time.utc(1999, 1, 4, 21)
        expect(series1.ticks.last.close_timestamp).to eq Time.utc(1999, 1, 7, 21)
      end

      it "has full indicators for series1" do
        expect(series1.indicators.oc2.ping.count).to eq 4
        expect(series1.indicators.oc2.ping.first.pong).to eq 3.0
        expect(series1.indicators.oc2.ping[-1].pong).to eq 24.0
      end

      it "has full date range for series2" do
        expect(series2.ticks.count).to eq 4
        expect(series2.ticks.first.close_timestamp).to eq Time.utc(1999, 1, 4, 21)
        expect(series2.ticks.last.close_timestamp).to eq Time.utc(1999, 1, 7, 21)
      end

      it "has full indicator for series2" do
        expect(series2.indicators.oc2.ping.count).to eq 4
        expect(series1.indicators.oc2.ping.map(&:pong)).to eq [3.0, 6.0, 12.0, 24.0]
      end
    end

    context "when limited" do
      let(:filename) { fixture_filename("DEUCES-sample.txt", :series) }
      let(:series1) { described_class.from_file(filename:, symbol: "DEUCES", interval: "1d") }

      let(:period) { (series1.ticks[1].open_timestamp..series1.ticks[2].close_timestamp) }
      let(:series2) { series1.limit(period) }

      it "has full date range for series1" do
        expect(series1.ticks.count).to eq 4
        expect(series1.ticks.first.close_timestamp).to eq Time.utc(1999, 1, 4, 21)
        expect(series1.ticks.last.close_timestamp).to eq Time.utc(1999, 1, 7, 21)
      end

      it "it limits the indicators to the subset of ticks" do
        expect(series1.indicators.oc2.ping.map(&:pong)).to eq [3.0, 6.0, 12.0, 24.0]
        expect(series2.indicators.oc2.ping.map(&:pong)).to eq [6.0, 12.0]
      end

      it "has shorter date range for series2" do
        expect(series2.ticks.count).to eq 2
        expect(series2.ticks.first.close_timestamp).to eq Time.utc(1999, 1, 5, 21)
        expect(series2.ticks.last.close_timestamp).to eq Time.utc(1999, 1, 6, 21)
        expect(series2.ticks[0]).to eq series1.ticks[1]
        expect(series2.ticks[1]).to eq series1.ticks[2]
      end

      it "has fewer indicators for series2" do
        expect(series2.indicators.oc2.ping.size).to eq 2
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

  describe "#interval" do
    let(:series) { described_class.new(symbol: appl, interval: "1d") }
    let(:series2) { described_class.new(symbol: appl, interval: Quant::Interval.new("1m")) }

    it { expect(series.interval).to eq Quant::Interval["1d"] }
    it { expect(series2.interval).to eq Quant::Interval["1m"] }

    it { expect(series.interval).to eq "1d" }
    it { expect(series2.interval).to eq "1m" }
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

  describe "#reject!" do
    let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
    let(:series2) { described_class.from_file(filename: ibm_fixture_filename, symbol: ibm, interval: "1d") }
    let(:tick) { series1[2] }

    subject { series1.reject! { |t| t == tick } }

    it { expect{ subject }.to change{ series1.ticks.size }.from(4).to(3) }
  end

  describe "#select" do
    let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
    let(:series2) { described_class.from_file(filename: ibm_fixture_filename, symbol: ibm, interval: "1d") }
    let(:tick) { series1.last }

    subject { series1.select { |t| t == tick } }

    it { expect{ subject }.not_to change{ series1.ticks.size } }
  end

  describe "#reject" do
    let(:series1) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }
    let(:series2) { described_class.from_file(filename: ibm_fixture_filename, symbol: ibm, interval: "1d") }
    let(:tick) { series1.first }

    subject { series1.reject { |t| t == tick } }

    it { expect{ subject }.not_to change{ series1.ticks.size } }
  end

  describe "#indicators" do
    let(:series) { described_class.from_file(filename: apple_fixture_filename, symbol: appl, interval: "1d") }

    subject { series.indicators }

    it { is_expected.to be_a(Quant::IndicatorsSources) }
    it { expect(subject.oc2).to be_a(Quant::IndicatorsProxy) }
    it { expect(subject.oc2.ping).to be_a(Quant::Indicators::Ping) }
    it { expect(subject.oc2.ping.first).to be_a(Quant::Indicators::PingPoint) }
  end
end
