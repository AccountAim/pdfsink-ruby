# frozen_string_literal: true

module Pdfsink
  # A PDF document opened from a file on disk.
  #
  # Opening is cheap: the path is validated and the document's +info+ payload
  # (page count and per-page metadata) is fetched lazily on first access.
  # {Page} objects are created on demand and memoized. {#load_all} reads
  # every page's text and table in one run.
  #
  # @example
  #   doc = Pdfsink::Document.open("report.pdf")
  #   doc.page_count          # => 12
  #   doc.page(1).extract_text
  #   doc.pages.flat_map(&:extract_words)
  class Document
    # @return [String] absolute path to the PDF file
    attr_reader :path

    # Open a PDF document.
    #
    # @param path [String] path to a PDF file
    # @return [Document]
    # @raise [Errno::ENOENT] if the file does not exist
    def self.open(path)
      new(path)
    end

    # @param path [String] path to a PDF file
    def initialize(path)
      @path = File.expand_path(path)
      raise Errno::ENOENT, @path unless File.exist?(@path)

      @pages = {}
    end

    # Document and per-page metadata as returned by the binary.
    #
    # @return [Hash]
    def info
      @info ||= Cli.info(path)
    end

    # @return [Integer] number of pages
    def page_count
      info["page_count"]
    end
    alias length page_count
    alias size page_count

    # Fetch a single page.
    #
    # @param number [Integer] 1-based page number
    # @return [Page]
    # @raise [RangeError] if the page number is out of range
    def page(number)
      unless number.is_a?(Integer) && number >= 1 && number <= page_count
        raise RangeError, "page #{number} out of range (1..#{page_count})"
      end

      @pages[number] ||= Page.new(self, number, info["pages"][number - 1])
    end

    # All pages, in order.
    #
    # @return [Array<Page>]
    def pages
      (1..page_count).map { |n| page(n) }
    end

    # Iterate over each page.
    #
    # @yieldparam page [Page]
    # @return [Enumerator] if no block is given
    def each_page(&block)
      return enum_for(:each_page) unless block

      pages.each(&block)
    end

    # Read the text and largest table of every page in one run of the
    # binary. Afterwards {Page#extract_text}, and {Page#tables} with the same
    # strategy, return without running it again. Use this when you need
    # every page; for a few pages, the per-page methods are faster.
    #
    # Each call parses the whole document again, so a second strategy needs a
    # second call. {Page#extract_words}, {Page#objects}, {Page#links} and
    # {Page#search} are not preloaded.
    #
    # @param strategy [Symbol, String, nil] table-detection strategy
    # @return [Array<Page>]
    def load_all(strategy: nil)
      strategy = TableStrategy.resolve(strategy)
      payload  = Cli.pages(path, strategy)
      entries  = payload["pages"]

      @info = payload.merge("pages" => entries.map { |entry| entry.except("text", "table") })
      entries.each.with_index(1) do |entry, number|
        # The text command prints a trailing newline; pages does not.
        page(number).preload(text: "#{entry['text']}\n", strategy: strategy, table: entry["table"])
      end
      pages
    end

    def inspect
      "#<Pdfsink::Document path=#{path.inspect} pages=#{page_count}>"
    end
  end
end
