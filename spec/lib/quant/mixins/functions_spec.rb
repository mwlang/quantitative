# frozen_string_literal: true

RSpec.describe Quant::Mixins::Functions do
  let(:klass) do
    Class.new do
      include Quant::Mixins::Functions
    end
  end

  subject { klass.new }

  describe "#period_to_alpha" do
    it { expect(subject.period_to_alpha(4.0)).to eq(0.0) }
    it { expect(subject.period_to_alpha(5.0)).to eq(0.841615559675464) }
    it { expect(subject.period_to_alpha(6.0)).to eq(0.7320508075688775) }
    it { expect(subject.period_to_alpha(10.0)).to eq(0.4904745505055712) }
    it { expect(subject.period_to_alpha(20.0)).to eq(0.273457471994639) }
    it { expect(subject.period_to_alpha(40.0)).to eq(0.14591931453653348) }
    it { expect(subject.period_to_alpha(50.0)).to eq(0.11838140763681106) }
  end

  describe "#bars_to_alpha" do
    it { expect(subject.bars_to_alpha(3)).to eq(0.5) }
    it { expect(subject.bars_to_alpha(4)).to eq(0.4) }
    it { expect(subject.bars_to_alpha(5)).to eq(0.3333333333333333) }
    it { expect(subject.bars_to_alpha(6)).to eq(0.2857142857142857) }
    it { expect(subject.bars_to_alpha(10)).to eq(0.18181818181818182) }
    it { expect(subject.bars_to_alpha(20)).to eq(0.09523809523809523) }
    it { expect(subject.bars_to_alpha(40)).to eq(0.04878048780487805) }
    it { expect(subject.bars_to_alpha(50)).to eq(0.0392156862745098) }
  end

  describe "#deg2rad" do
    it { expect(subject.deg2rad(90)).to eq(Math::PI * 0.5) }
    it { expect(subject.deg2rad(180)).to eq(Math::PI) }
    it { expect(subject.deg2rad(360)).to eq(Math::PI * 2) }
  end

  describe "#rad2deg" do
    it { expect(subject.rad2deg(Math::PI * 0.5)).to eq(90) }
    it { expect(subject.rad2deg(Math::PI)).to eq(180) }
    it { expect(subject.rad2deg(Math::PI * 2)).to eq(360) }
  end

  describe "#angle" do
    it { expect(subject.angle([[0, 0], [1, 1]], [[0, 0], [1, 1]])).to eq(0.0) }
    it { expect(subject.angle([[0, 0], [1, 1]], [[1, 1], [2, 2]])).to eq(0.0) }
    it { expect(subject.angle([[0, 0], [1, 1]], [[1, 1], [2, 0]])).to eq(90.0) }
    it { expect(subject.angle([[0, 0], [0, 1]], [[1, 1], [1, 1]]).round(2)).to eq(45.0) }
  end
end
