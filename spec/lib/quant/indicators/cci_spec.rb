# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Indicators::Cci do
  subject { described_class.new(series:, source:) }

  context "sine series" do
    let(:source) { :oc2 }
    let(:period) { 40 }
    let(:cycles) { 5 }
    let(:uniq_data_points) { cycles * period / cycles } # sine is cyclical, so we expect a few unique data points
    let(:series) do
      # period bar sine wave
      Quant::Series.new(symbol: "SINE", interval: "1d").tap do |series|
        cycles.times do
          (0...period).each do |degree|
            radians = degree * 2 * Math::PI / period
            series << 5.0 * Math.sin(radians) + 10.0
          end
        end
      end
    end

    it { expect(subject.series.size).to eq(cycles * period) }

    it { expect(subject.values.map(&:state).uniq).to eq([-1, 0, 1]) }

    it "is roughly evenly distributed" do
      states = subject.values.map(&:state).group_by(&:itself).transform_values(&:count)

      expect(states).to eq({ -1 => 52, 0 => 83, 1 => 65 })
    end
  end
end
