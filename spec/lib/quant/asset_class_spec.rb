# frozen_string_literal: true

RSpec.describe Quant::AssetClass do
  subject { described_class.new(name) }

  context "when initialized with a standard name symbol" do
    let(:name) { :stock }
    let(:json) { Oj.dump({ "sc" => :stock }) }

    it { is_expected.to be_stock }
    it { expect(subject.asset_class).to eq :stock }
    it { expect(subject.to_h).to eq({ "sc" => :stock }) }
    it { expect(subject.to_json).to eq(json) }
    it { expect(subject.to_s).to eq("stock") }

    context "comparable" do
      it { expect(subject == "stock").to be true }
      it { expect(subject == :stock).to be true }
      it { expect(subject == "us_equity").to be true }
      it { expect(subject == described_class.new("stock")).to be true }
      it { expect(subject == 99).to be false }
    end
  end

  context "when initialized with a standard name String" do
    let(:name) { "ETF" }
    let(:json) { Oj.dump({ "sc" => :etf }) }

    it { is_expected.to be_etf }
    it { expect(subject.asset_class).to eq :etf }
    it { expect(subject.to_h).to eq({ "sc" => :etf }) }
    it { expect(subject.to_json).to eq(json) }
  end

  context "when initialized with an alternate name" do
    let(:name) { "us_equity" }
    let(:json) { Oj.dump({ "sc" => :stock }) }

    it { is_expected.to be_stock }
    it { expect(subject.asset_class).to eq :stock }
    it { expect(subject.to_h).to eq({ "sc" => :stock }) }
    it { expect(subject.to_json).to eq(json) }
  end

  context "when initialized with nil" do
    let(:name) { nil }

    it "raises an error" do
      expect { subject }.to raise_error Quant::Errors::AssetClassError, "Unknown asset class: nil"
    end
  end

  context "when initialized with bogus" do
    let(:name) { "bogus" }

    it "raises an error" do
      expect { subject }.to raise_error Quant::Errors::AssetClassError, 'Unknown asset class: "bogus"'
    end
  end
end
