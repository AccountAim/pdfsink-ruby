# frozen_string_literal: true

module Pdfsink
  # A single page of a {Document}.
  #
  # Each accessor shells out to the pdfsink-rs binary for that page; results
  # are cached so repeated reads don't re-spawn the process. Page-level
  # metadata (dimensions, rotation, bbox, object counts) comes from the
  # document's +info+ payload and needs no extra spawn.
  #
  # @example
  #   doc  = Pdfsink::Document.open("report.pdf")
  #   page = doc.page(1)
  #   page.width            # => 612.0
  #   page.extract_text     # => "Quarterly Report\n..."
  #   page.tables           # => [[["Q1", "Q2"], ["10", "20"]]]
  class Page
    # @return [Integer] 1-based page number
    attr_reader :number

    # @param document [Document]
    # @param number [Integer] 1-based page number
    # @param meta [Hash] the per-page slice of the document +info+ payload
    def initialize(document, number, meta)
      @document = document
      @number   = number
      @meta     = meta
    end

    # @return [Float] page width in PDF points
    def width = @meta["width"]

    # @return [Float] page height in PDF points
    def height = @meta["height"]

    # @return [Integer] clockwise rotation in degrees (0, 90, 180, 270)
    def rotation = @meta["rotation"]

    # @return [Hash] the page bounding box ({"x0", "top", "x1", "bottom"})
    def bbox = @meta["bbox"]

    # @return [Hash] counts of each object kind on the page
    def object_counts = @meta["object_counts"]

    # The page's text in reading order.
    #
    # @return [String]
    def extract_text
      @extract_text ||= Cli.text(path, number)
    end

    # Words with positions and font metadata.
    #
    # @return [Array<Hash>]
    def extract_words
      @extract_words ||= Cli.words(path, number)
    end

    # Every page object (chars, lines, rects, curves, images, annots, ...).
    #
    # @return [Hash] keyed by object kind
    def objects
      @objects ||= Cli.objects(path, number)
    end

    # Hyperlinks on the page.
    #
    # @return [Array<Hash>]
    def links
      @links ||= Cli.links(path, number)
    end

    # Regex search matches within the page text.
    #
    # @param pattern [String, Regexp] the pattern to search for
    # @return [Array<Hash>]
    def search(pattern)
      Cli.search(path, number, pattern.is_a?(Regexp) ? pattern.source : pattern.to_s)
    end

    # The page's largest detected table, or nil if none is found.
    #
    # @param strategy [Symbol, String, nil] table-detection strategy
    # @return [Array<Array>, nil] rows of cells
    def tables(strategy: nil)
      Cli.table(path, number, TableStrategy.resolve(strategy))
    end

    def inspect
      "#<Pdfsink::Page number=#{number} #{width}x#{height}>"
    end

    private

    def path = @document.path
  end
end
