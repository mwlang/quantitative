# frozen_string_literal: true

module Quant
  module Mixins
    module SuperSmoother
      def super_smoother(source, prev_source, period)
        v0 = (source.is_a?(Symbol) ? p0.send(source) : source).to_d
        return v0.to_f if points.size < 4

        k = Math.exp(-Math.sqrt(2) * Math::PI / period)
        coef3 = -k**2
        coef2 = 2.0 * k * Math.cos(Math.sqrt(2) * (Math::PI / 2) / period)
        coef1 = 1.0 - coef2 - coef3

        v1 = p1.send(prev_source).to_d
        v2 = p2.send(prev_source).to_d
        p3.send(prev_source).to_d
        ((coef1 * (v0 + v1)) / 2.0 + (coef2 * v1) + (coef3 * v2)).to_f
      end

      def two_pole_super_smooth(source, prev_source, ssperiod)
        return p1.send(source) if [p1 == p3]

        radians = Math::PI * Math.sqrt(2) / ssperiod
        a1 = Math.exp(-radians)

        coef2 = 2.0 * a1 * Math.cos(radians)
        coef3 = -a1 * a1
        coef1 = 1.0 - coef2 - coef3

        v0 = (p1.send(source) + p2.send(source)) / 2.0
        v1 = p2.send(prev_source)
        v2 = p3.send(prev_source)
        (coef1 * v0) + (coef2 * v1) + (coef3 * v2)
      end

      def three_pole_super_smooth(source, prev_source, ssperiod)
        a1 = Math.exp(-Math::PI / ssperiod)
        b1 = 2 * a1 * Math.cos(Math::PI * Math.sqrt(3) / ssperiod)
        c1 = a1**2

        coef2 = b1 + c1
        coef3 = -(c1 + b1 * c1)
        coef4 = c1**2
        coef1 = 1 - coef2 - coef3 - coef4

        p0 = prev(0)
        p1 = prev(1)
        p2 = prev(2)
        p3 = prev(3)

        v0 = source.is_a?(Symbol) ? p0.send(source) : source
        return v0 if [p0, p1, p2].include?(p3)

        v1 = p1.send(prev_source)
        v2 = p2.send(prev_source)
        v3 = p3.send(prev_source)
        (coef1 * v0) + (coef2 * v1) + (coef3 * v2) + (coef4 * v3)
      end

      # super smoother 3 pole
      def ss3p(source, prev_source, ssperiod)
        p0 = points[-1]
        p1 = points[-2] || p0
        p2 = points[-3] || p1
        p3 = points[-4] || p2

        v0 = source.is_a?(Symbol) ? p0.send(source) : source
        return v0 if [p0 == p3]

        debugger if points.size > 4
        a1 = Math.exp(-Math::PI / ssperiod)
        b1 = 2 * a1 * Math.cos(Math::PI * Math.sqrt(3) / ssperiod)
        c1 = a1**2

        coef2 = b1 + c1
        coef3 = -(c1 + b1 * c1)
        coef4 = c1**2
        coef1 = 1 - coef2 - coef3 - coef4

        v1 = p1.send(prev_source)
        v2 = p2.send(prev_source)
        v3 = p3.send(prev_source)
        (coef1 * v0) + (coef2 * v1) + (coef3 * v2) + (coef4 * v3)
      end

      #   attr_reader :hpfs, :value1s, :hpf_psns

      #   def hpf
      #     @hpfs[-1]
      #   end

      #   def hpf_psn
      #     @hpf_psns[-1]
      #   end

      #   def prev offset, source
      #     idx = offset + 1
      #     source[[-idx, -source.size].max]
      #   end

      #   def weighted_average source
      #     [ 4.0 * prev(0, source),
      #       3.0 * prev(1, source),
      #       2.0 * prev(2, source),
      #             prev(3, source),
      #     ].sum / 10.0
      #   end

      #   def compute_hpf
      #     @hpfs ||= []
      #     @value1s ||= []
      #     @hpf_psns ||= []
      #     max_cycle = period * 10

      #     r = (360.0 / max_cycle) * (Math::PI / 180)
      #     alpha = (1 - Math::sin(r)) / Math::cos(r)
      #     hpf = @hpfs.empty? ? 0.0 : (0.5 * (1.0 + alpha) * (current_value - prev_value(1))) + (alpha * (@hpfs[-1]))

      #     @hpfs << hpf
      #     @hpfs.shift if @hpfs.size > max_cycle

      #     hh = @hpfs.max
      #     ll = @hpfs.min
      #     @value1s << value1 = (hh == ll ? 0.0 : 100 * (hpf - ll) / (hh - ll))
      #     @value1s.shift if @value1s.size > max_cycle

      #     @hpf_psns << weighted_average(@value1s)
      #     @hpf_psns.shift if @hpf_psns.size > max_cycle
      #   end
    end
  end
end
