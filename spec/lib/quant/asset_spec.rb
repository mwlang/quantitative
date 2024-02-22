# frozen_string_literal: true

require "spec_helper"

RSpec.describe Quant::Asset do
  context "from Alpaca Asset" do
    let(:asset) do
      {
        "id" => "21d40833-6d13-4031-9af3-02f6a516d791",
        "class" => "us_equity",
        "exchange" => "NYSE",
        "symbol" => "IBM",
        "name" => "International Business Machines Corporation",
        "status" => "active",
        "tradable" => true,
        "marginable" => true,
        "maintenance_margin_requirement" => 30,
        "shortable" => true,
        "easy_to_borrow" => true,
        "fractionable" => true,
        "attributes" => []
      }
    end

    let(:asset_from_asset) do
      described_class.new(
        symbol: asset["symbol"],
        name: asset["name"],
        id: asset["id"],
        tradeable: asset["tradable"],
        active: asset["status"] == "active",
        exchange: asset["exchange"],
        asset_class: asset["class"],
        source: :alpaca,
        meta: asset
      )
    end

    subject { asset_from_asset }

    it { is_expected.to be_a Quant::Asset }
    it { is_expected.to have_attributes(symbol: "IBM") }
    it { is_expected.to have_attributes(name: "International Business Machines Corporation") }
    it { is_expected.to be_active }
    it { is_expected.to be_tradeable }
    it { is_expected.to be_stock }
    it { expect(subject.symbol).to eq "IBM" }
    it { expect(subject.name).to eq "International Business Machines Corporation" }
    it { expect(subject.id).to eq "21d40833-6d13-4031-9af3-02f6a516d791" }
    it { expect(subject.exchange).to eq "NYSE" }
    it { expect(subject.asset_class).to eq :stock }
    it { expect(subject.source).to eq :alpaca }
    it { expect(subject.meta).to eq asset }
    it { expect(subject.created_at).to be_a Time }
    it { expect(subject.updated_at).to be_a Time }

    context "#to_h" do
      context "full: false" do
        it { expect(subject.to_h).to eq({ "s" => "IBM" }) }
        it { expect(subject.to_json).to eq("{\"s\":\"IBM\"}") }
      end

      context "full: true" do
        let(:expected_hash) do
          { "s" => "IBM",
            "n" => "International Business Machines Corporation",
            "id" => "21d40833-6d13-4031-9af3-02f6a516d791",
            "t" => true,
            "a" => true,
            "x" => "NYSE",
            "sc" => "stock",
            "src" => "alpaca"
          }
        end
        let(:expected_json) do
          Oj.dump(expected_hash)
        end

        it { expect(subject.to_h(full: true)).to eq expected_hash }
        it { expect(subject.to_json(full: true)).to eq expected_json }
      end
    end
  end
end
