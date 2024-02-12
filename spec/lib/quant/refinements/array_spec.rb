require "spec_helper"

RSpec.describe Array do
  let(:quant_array) { [1, 2, 3, 4, 5] }

  TOP_LEVEL_ARRAY = [1, 2, 3, 4, 5]

  subject { quant_array }

  context 'when NOT refined' do
    it { is_expected.to be_a(Array) }
    it { expect { subject.mean }.to raise_error(NoMethodError) }
    it { expect { TOP_LEVEL_ARRAY.mean }.to raise_error(NoMethodError) }
  end

  context "when refined" do
    using Quant

    describe '#mean' do
      it { is_expected.to be_a(Array) }
      it { expect { subject.mean }.not_to raise_error }
      it { expect(subject.mean).to eq 3.0 }
      it { expect(TOP_LEVEL_ARRAY.mean).to eq 3.0 }
    end

    describe "#period" do
      [ [0, []],
        [1, [5]],
        [2, [4, 5]],
        [3, [3, 4, 5]],
        [4, [2, 3, 4, 5]],
        [5, [1, 2, 3, 4, 5]],
        [6, [1, 2, 3, 4, 5]]
      ].each do |n, expected|
        it "is #{expected.inspect} when n: is #{n}" do
          expect(quant_array.period(n: n)).to eq expected
        end
      end
    end

    describe "#ema(n:)" do
      [ [0, []],
        [1, [5.0]],
        [2, [4.0, 4.666666666666666]],
        [3, [3.0, 3.5, 4.25]],
        [4, [2.0, 2.4000000000000004, 3.04, 3.824]],
        [5, [1.0, 1.3333333333333335, 1.888888888888889, 2.5925925925925926, 3.3950617283950617]],
        [6, [1.0, 1.3333333333333335, 1.888888888888889, 2.5925925925925926, 3.3950617283950617]]
      ].each do |n, expected|
        it "is #{expected.inspect} when n: is #{n}" do
          expect(quant_array.ema(n: n)).to eq expected
        end
      end
    end

    describe "#sma(n:)" do
      [ [0, []],
        [1, [5.0]],
        [2, [4.0, 4.5]],
        [3, [3.0, 3.5, 4.25]],
        [4, [2.0, 2.5, 3.25, 4.125]],
        [5, [1.0, 1.5, 2.25, 3.125, 4.0625]],
        [6, [1.0, 1.5, 2.25, 3.125, 4.0625]]
      ].each do |n, expected|
        it "is #{expected.inspect} when n: is #{n}" do
          expect(quant_array.sma(n: n)).to eq expected
        end
      end
    end

    describe "#wma(n:)" do
      [ [0, []],
        [1, [5.0]],
        [2, [4.0, 4.4]],
        [3, [3.0, 3.4, 4.1]],
        [4, [2.0, 2.4, 3.1, 4.0]],
        [5, [1.0, 1.4, 2.1, 3.0, 4.0]],
        [6, [1.0, 1.4, 2.1, 3.0, 4.0]],
      ].each do |n, expected|
        it "is #{expected.inspect} when n: is #{n}" do
          expect(quant_array.wma(n: n)).to eq expected
        end
      end
    end

    describe '#stddev and #var' do
      context 'as reference: varies' do
        [ [0.0, 3.3166247903554, 11.0],
          [1.0, 2.449489742783178, 6.0],
          [2.0, 1.7320508075688772, 3.0],
          [3.0, 1.4142135623730951, 2.0],
          [3.5, 1.5, 2.25],
          [4.0, 1.7320508075688772, 3.0],
          [5.0, 2.449489742783178, 6.0],
          [6.0, 3.3166247903554, 11.0],
        ].each do |reference, expected_stdev, expected_variance|
          it "stdev=#{expected_stdev}, var=#{expected_variance} when reference is #{reference}" do
            expect(quant_array.stddev(reference)).to eq expected_stdev
            expect(quant_array.std_dev(reference)).to eq expected_stdev
            expect(quant_array.standard_deviation(reference)).to eq expected_stdev

            expect(quant_array.var(reference)).to eq expected_variance
            expect(quant_array.variance(reference)).to eq expected_variance
          end
        end
      end

      context 'as n: varies' do
        [ [0, 0.0, 0.0],
          [1, 1.5, 2.25],
          [2, 1.118033988749895, 1.25],
          [3, 0.9574271077563381, 0.9166666666666666],
          [4, 1.118033988749895, 1.25],
          [5, 1.5, 2.25],
          [6, 1.5, 2.25],
        ].each do |n, expected_stdev, expected_variance|
          it "stdev=#{expected_stdev}, var=#{expected_variance} when n: is #{n}" do
            expect(quant_array.stddev(3.5, n: n)).to eq expected_stdev
            expect(quant_array.var(3.5, n: n)).to eq expected_variance
          end
        end
      end
    end
  end
end