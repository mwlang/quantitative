# frozen_string_literal: true

RSpec.describe Quant::Indicators::Cci do
  subject { described_class.new(series:, source:) }

  context "sine series" do
    let(:source) { :oc2 }
    let(:period) { 40 }
    let(:cycles) { 5 }
    let(:series) { sine_series(period:, cycles:) }

    it { expect(subject.series.size).to eq(cycles * period) }

    it { expect(subject.values.map(&:state).uniq).to eq([-1, 0, 1]) }

    it "is roughly evenly distributed" do
      states = subject.values.map(&:state).group_by(&:itself).transform_values(&:count)

      expect(states).to eq({ -1 => 52, 0 => 83, 1 => 65 })
    end
  end
end
