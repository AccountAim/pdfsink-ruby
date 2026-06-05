# frozen_string_literal: true

module Pdfsink
  # The table-detection strategies supported by pdfsink-rs.
  #
  # Each constant holds the string the CLI's +table+ command expects.
  # Use symbols or strings interchangeably in the public API --
  # {TableStrategy.resolve} normalizes them.
  #
  # @example
  #   page.tables(strategy: Pdfsink::TableStrategy::TEXT)
  #   page.tables(strategy: :text)  # same thing
  module TableStrategy
    # Detect cell boundaries from ruling lines.
    LINES = "lines"

    # Like LINES, but only lines that meet at corners delimit cells.
    LINES_STRICT = "lines_strict"

    # Infer boundaries from text alignment when there are no ruling lines.
    TEXT = "text"

    # Use caller-supplied explicit vertical/horizontal lines.
    EXPLICIT = "explicit"

    # All known strategy names.
    ALL = [LINES, LINES_STRICT, TEXT, EXPLICIT].freeze

    # Normalize a strategy argument to the string the CLI expects.
    #
    # Accepts symbols, strings, or nil (nil -> the configured default,
    # falling back to "lines"). Unknown values raise ArgumentError.
    #
    # @param name [Symbol, String, nil]
    # @return [String]
    def self.resolve(name)
      name = Pdfsink.configuration.default_table_strategy if name.nil?
      name = LINES if name.nil?

      key = name.to_s.downcase.strip
      return key if ALL.include?(key)

      raise ArgumentError, "Unknown table strategy: #{name.inspect}. " \
                           "Known strategies: #{ALL.join(', ')}"
    end
  end
end
