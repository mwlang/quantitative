# frozen_string_literal: true

RSpec.describe Quant::Experimental do
  subject { described_class }

  it { is_expected.to respond_to(:tracker) }

  it "emits a message" do
    expect(described_class).to receive(:rspec_defined?).and_return(false)
    expect { Quant.experimental("foo") }.to output(/EXPERIMENTAL/).to_stdout
  end

  it "does not emit a message if rspec is defined" do
    expect { Quant.experimental("foo") }.not_to output(/EXPERIMENTAL/).to_stdout
  end
end
