# frozen_string_literal: true

module Quant
  module Config
    class Config
      attr_reader :indicators

      def initialize
        @indicators = Settings::Indicators.defaults
      end

      def apply_indicator_settings(**settings)
        @indicators.apply_settings(**settings)
      end
    end

    def self.default!
      @config = Config.new
    end

    def self.config
      @config ||= default!
    end
  end

  module_function

  def config
    Config.config
  end

  def default_configuration!
    Config.default!
  end

  def configure_indicators(**settings)
    config.apply_indicator_settings(**settings)
    yield config.indicators if block_given?
  end
end
