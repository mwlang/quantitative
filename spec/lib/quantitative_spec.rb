# frozen_string_literal: true

RSpec.describe Quant do
  it "has a version number" do
    expect(Quant::VERSION).not_to be nil
  end

  it "gives a current time" do
    expect(Quant.current_time).to be_within(5).of(Time.now)
  end

  describe ".config" do
    it { expect(Quant.config).to be_a(Quant::Config::Config) }
  end

  describe ".config.indicators" do
    it { expect(Quant.config.indicators).to be_a(Quant::Settings::Indicators) }
  end
end
