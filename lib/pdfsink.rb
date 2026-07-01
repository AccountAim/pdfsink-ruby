# frozen_string_literal: true

require_relative "pdfsink/version"
require_relative "pdfsink/error"
require_relative "pdfsink/table_strategy"
require_relative "pdfsink/cli"
require_relative "pdfsink/page"
require_relative "pdfsink/document"

# Load the Railtie only when Rails is present.
require_relative "pdfsink/railtie" if defined?(Rails::Railtie)

# Pdfsink wraps the pdfsink-rs CLI, a fast pure-Rust PDF extraction tool,
# exposing text, word, object, table, link, and search extraction to Ruby.
#
# @example Open a document and read a page
#   doc = Pdfsink.open("report.pdf")
#   doc.page_count            # => 12
#   doc.page(1).extract_text  # => "Quarterly Report\n..."
#
# @example One-shot text extraction
#   Pdfsink.extract_text("report.pdf", page: 1)
#
# @example Tables
#   Pdfsink.open("invoice.pdf").page(1).tables(strategy: :text)
module Pdfsink
  # ── Configuration ────────────────────────────────────────────────────

  class Configuration
    # Strategy used by {Page#tables} when none is given. Defaults to "lines".
    # @return [Symbol, String, nil]
    attr_accessor :default_table_strategy

    def initialize
      @default_table_strategy = nil
    end
  end

  class << self
    # @return [Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the configuration object for modification.
    #
    # @example
    #   Pdfsink.configure do |config|
    #     config.default_table_strategy = :text
    #   end
    def configure
      yield(configuration)
    end

    # ── Public API ───────────────────────────────────────────────────

    # Open a PDF document.
    #
    # @param path [String] path to a PDF file
    # @return [Document]
    def open(path)
      Document.open(path)
    end

    # Extract the text of a single page in one call.
    #
    # @param path [String]
    # @param page [Integer] 1-based page number
    # @return [String]
    def extract_text(path, page: 1)
      Cli.text(File.expand_path(path), page)
    end

    # The version of the underlying pdfsink-rs binary the gem was built with.
    #
    # @return [String] e.g. "0.2.9"
    def version
      Cli.version
    end
  end
end
