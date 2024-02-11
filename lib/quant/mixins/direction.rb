# frozen_string_literal: true

module Quant
  module Mixins
    module Direction
      def direction(average, current)
        if average < current
          :up
        elsif average > current
          :down
        else
          :flat
        end
      end

      def dir_label(average, current)
        { up: "UP", flat: "--", down: "DN" }[direction(average, current)]
      end

      def up?
        direction == :up
      end

      def flat?
        direction == :flat
      end

      def down?
        direction == :down
      end

      def up_or_flat?
        up? || flat?
      end

      def down_or_flat?
        down? || flat?
      end

      def dir_label(colorize)
        dir_label(average, psn, colorize)
      end
    end
  end
end
