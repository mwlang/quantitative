# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Ticks::Tick do
  Quant::Ticks::Serializers::Tick.class_eval do
    def self.to_h(_tick)
      { "iv" => "1d", "ct" => 9999, "cp" => 5.0 }
    end
  end

  subject(:tick) { described_class.new }

  describe "#assign_series" do
    let(:indicators) { instance_double(Quant::IndicatorsSources) }
    let(:series) { instance_double(Quant::Series, interval: "1d", indicators:) }
    let(:another_series) { instance_double(Quant::Series) }

    before do
      allow(indicators).to receive(:<<) { |tick| tick }
    end

    it { expect(tick.series).to be_nil }

    it "assigns the series" do
      expect { tick.assign_series(series) }.to change(tick, :series).from(nil).to(series)
    end

    it "does not reassign another series" do
      expect { tick.assign_series(series) }.to change(tick, :series).from(nil).to(series)
      expect { tick.assign_series(another_series) }.not_to change(tick, :series).from(series)
    end
  end

  describe "#interval" do
    context "before a series is assigned" do
      it { expect(tick.interval).to eq Quant::Interval[nil] }
      it { expect(tick.interval).to be_nil }
    end

    context "when a series is assigned" do
      let(:series) { instance_double(Quant::Series, interval: "1d") }

      before { tick.assign_series(series) }

      it { expect(series.interval).to eq "1d" }
      it { expect(tick.interval).to eq "1d" }
    end
  end

  describe "#to_h" do
    let(:output) { { "iv" => "1d", "ct" => 9999, "cp" => 5.0 } }

    it "renders with default serializer" do
      expect(tick.to_h).to eq output
    end

    it "renders with given serializer" do
      serializer = Quant::Ticks::Serializers::Tick
      expect(tick.to_h(serializer_class: serializer)).to eq output
    end
  end

  describe "#to_json" do
    let(:output) { "{\"iv\":\"1d\",\"ct\":9999,\"cp\":5.0}" }

    it "renders with default serializer" do
      expect(tick.to_json).to eq output
    end

    it "renders with given serializer" do
      serializer = Quant::Ticks::Serializers::Tick
      expect(tick.to_json(serializer_class: serializer)).to eq output
    end
  end

  describe "#to_csv" do
    let(:output) { "1d,9999,5.0\n" }

    it "renders with default serializer" do
      expect(tick.to_csv).to eq output
    end

    it "renders with given serializer" do
      serializer = Quant::Ticks::Serializers::Tick
      expect(tick.to_csv(serializer_class: serializer)).to eq output
    end

    it "renders with header row" do
      expect(tick.to_csv(headers: true)).to eq "iv,ct,cp\n1d,9999,5.0\n"
    end
  end
end
