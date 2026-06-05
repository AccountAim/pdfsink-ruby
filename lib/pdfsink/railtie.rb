# frozen_string_literal: true

module Pdfsink
  # Rails integration. Loaded automatically when +Rails::Railtie+ is
  # defined (see +lib/pdfsink.rb+).
  #
  # @example config/application.rb
  #   config.pdfsink.default_table_strategy = :text
  #   config.pdfsink.binary_path = Rails.root.join("bin/pdfsink-rs").to_s
  class Railtie < Rails::Railtie
    config.pdfsink = ActiveSupport::OrderedOptions.new

    initializer "pdfsink.configure" do |app|
      cfg = app.config.pdfsink

      Pdfsink.configure do |c|
        c.default_table_strategy = cfg.default_table_strategy if cfg.default_table_strategy
      end

      Cli.binary = cfg.binary_path if cfg.binary_path
    end
  end
end
