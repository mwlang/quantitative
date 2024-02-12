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

    describe '#max_size!' do
      let(:new_array) { [] }
      let(:shovel_populated_array) { new_array.tap{ |array| 100.times{ |i| array << i } } }
      let(:push_populated_array) { new_array.tap{ |array| 100.times{ |i| array.push(i) } } }

      context 'before setting max_size!' do
        it { expect(shovel_populated_array.size).to eq 100 }
        it { expect(push_populated_array.size).to eq 100 }
      end

      context 'with max_size' do
        before { new_array.max_size!(25) }

        it { expect(shovel_populated_array.size).to eq 25 }
        it { expect(push_populated_array.size).to eq 25 }
      end

      context 'max_size! twice' do
        before { new_array.max_size!(25) }

        it { expect{ new_array.max_size!(50) }.to raise_error(Quant::ArrayMaxSizeError, /only.*once/) }
      end

      context 'max_size! whiny nil' do
        it { expect{ new_array.max_size!(nil) }.to raise_error(Quant::ArrayMaxSizeError, /cannot.*nil/) }
      end

      context 'max_size! with too many items' do
        let(:new_array) { Array.new(25, 0) }

        it { expect{ new_array.max_size!(50) }.not_to raise_error }
        it { expect{ new_array.max_size!(5) }.to raise_error Quant::ArrayMaxSizeError, /size.*exceeds max_size/ }
      end
    end

    describe '#maximum' do
      let(:unbounded) { Array.new }
      let(:bounded) { Array.new.max_size!(5) }

      def preload(array, n)
        n.times{ |v| array << v }
        array
      end

      it "is bounded" do
        q = preload(bounded, 5)
        expect(q.to_a).to eq [0,1,2,3,4]
        expect(q.min).to eq 0
        expect(q.max).to eq 4
        expect(q.minimum).to eq 0
        expect(q.maximum).to eq 4

        5.times{ |i| q << i + 5 }
        expect(q.to_a).to eq [5,6,7,8,9]
        expect(q.min).to eq 5
        expect(q.max).to eq 9
        expect(q.minimum).to eq 5
        expect(q.maximum).to eq 9
      end

      it "tracks push when bounded" do
        expect(Array.new.max_size!(3).push(1, 2, 3, 4, 5, 6)).to eq [4, 5, 6]
      end

      it "is unbounded" do
        q = preload(unbounded, 5)
        expect(q.to_a).to eq [0,1,2,3,4]
        expect(q.min).to eq 0
        expect(q.max).to eq 4
        expect(q.minimum).to eq 0
        expect(q.maximum).to eq 4

        5.times{ |i| q << i + 5 }
        expect(q.to_a).to eq [0,1,2,3,4,5,6,7,8,9]
        expect(q.min).to eq 0
        expect(q.max).to eq 9
        expect(q.minimum).to eq 0
        expect(q.maximum).to eq 9
      end
    end

    describe '#prev' do
      let(:q) { [0, 1, 2, 3, 4] }

      it "last item is the zeroth item" do
        expect(q.prev(0)).to eq q[4]
        expect(q.prev(1)).to eq q[3]
        expect(q.prev(2)).to eq q[2]
        expect(q.prev(3)).to eq q[1]
        expect(q.prev(4)).to eq q[0]
        expect(q.prev(5)).to eq q[0]
      end
    end

    describe '#mean' do
      it { is_expected.to be_a(Array) }
      it { expect { subject.mean }.not_to raise_error }
      it { expect(subject.mean).to eq 3.0 }
      it { expect(TOP_LEVEL_ARRAY.mean).to eq 3.0 }
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