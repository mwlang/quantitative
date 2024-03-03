# frozen_string_literal: true

module Quant
  module Mixins
    module Functions
      # α = Cos(K*360/Period)+Sin(K*360/Period)−1 / Cos(K*360/Period)
      # k = 1.0 for single-pole filters
      # k = 0.707 for two-pole high-pass filters
      # k = 1.414 for two-pole low-pass filters
      def period_to_alpha(period, k: 1.0)
        radians = deg2rad(k * 360 / period.to_f)
        cos = Math.cos(radians)
        sin = Math.sin(radians)
        (cos + sin - 1) / cos
      end

      # 3 bars = 0.5
      # 4 bars = 0.4
      # 5 bars = 0.333
      # 6 bars = 0.285
      # 10 bars = 0.182
      # 20 bars = 0.0952
      # 40 bars = 0.0488
      # 50 bars = 0.0392
      def bars_to_alpha(bars)
        2.0 / (bars + 1)
      end

      def deg2rad(degrees)
        degrees * Math::PI / 180.0
      end

      def rad2deg(radians)
        radians * 180.0 / Math::PI
      end

      # dx1 = x2-x1;
      # dy1 = y2-y1;
      # dx2 = x4-x3;
      # dy2 = y4-y3;

      # d = dx1*dx2 + dy1*dy2;   // dot product of the 2 vectors
      # l2 = (dx1*dx1+dy1*dy1)*(dx2*dx2+dy2*dy2) // product of the squared lengths
      def angle(line1, line2)
        dx1 = line2[0][0] - line1[0][0]
        dy1 = line2[0][1] - line1[0][1]
        dx2 = line2[1][0] - line1[1][0]
        dy2 = line2[1][1] - line1[1][1]

        d = dx1 * dx2 + dy1 * dy2
        l2 = ((dx1**2 + dy1**2) * (dx2**2 + dy2**2))

        radians = d.to_f / Math.sqrt(l2)
        value = rad2deg Math.acos(radians)

        value.nan? ? 0.0 : value
      end

      # angle = acos(d/sqrt(l2))
      #     public static double angleBetween2Lines(Line2D line1, Line2D line2)
      # {
      #     double angle1 = Math.atan2(line1.getY1() - line1.getY2(),
      #                                line1.getX1() - line1.getX2());
      #     double angle2 = Math.atan2(line2.getY1() - line2.getY2(),
      #                                line2.getX1() - line2.getX2());
      #     return angle1-angle2;
      # }
    end
  end
end
