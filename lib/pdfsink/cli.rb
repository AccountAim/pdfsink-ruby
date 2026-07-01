# frozen_string_literal: true

require "open3"
require "json"

module Pdfsink
  # Low-level runner for the pdfsink-rs CLI binary.
  #
  # This module is not intended for direct use -- see the public API on
  # {Pdfsink}, {Pdfsink::Document}, and {Pdfsink::Page} instead. Every method
  # shells out to the binary, returning either its raw stdout (for +text+) or
  # the parsed JSON it prints.
  #
  # @api private
  module Cli
    BINARY = "pdfsink-rs"

    class << self
      # Absolute path to the pdfsink-rs binary. Search order:
      #   1. PDFSINK_BIN environment variable (explicit override)
      #   2. lib/pdfsink/ inside the gem (where extconf.rb copies the build)
      #   3. ext/pdfsink/bin/ (dev / cargo-install location)
      #   4. The bare name, resolved against PATH at exec time
      #
      # @return [String]
      def binary
        @binary ||= find_binary
      end

      # Override the resolved binary path (mainly for tests).
      attr_writer :binary

      # The pdfsink-rs version string, e.g. "pdfsink-rs 0.2.9".
      #
      # The CLI has no version subcommand, so this reports the crate version
      # the gem was built against.
      #
      # @return [String]
      def version
        Pdfsink::PDFSINK_RS_VERSION
      end

      # Document-level metadata for every page: dimensions, rotation, bbox,
      # and per-page object counts.
      #
      # @param path [String]
      # @return [Hash]
      def info(path)
        run_json("info", path)
      end

      # Extracted text for a single page.
      #
      # @param path [String]
      # @param page [Integer] 1-based page number
      # @return [String]
      def text(path, page)
        run("text", path, page.to_s)
      end

      # Words with positions for a single page.
      #
      # @return [Array<Hash>]
      def words(path, page)
        run_json("words", path, page.to_s)
      end

      # Regex search matches for a single page.
      #
      # @return [Array<Hash>]
      def search(path, page, pattern)
        run_json("search", path, page.to_s, pattern)
      end

      # All page objects (chars, lines, rects, curves, images, ...) as a dict.
      #
      # @return [Hash]
      def objects(path, page)
        run_json("objects", path, page.to_s)
      end

      # Hyperlinks on a single page.
      #
      # @return [Array<Hash>]
      def links(path, page)
        run_json("links", path, page.to_s)
      end

      # Extracted table for a single page, or nil if none was found.
      #
      # @param strategy [String] one of "lines", "lines_strict", "text", "explicit"
      # @return [Array<Array>, nil]
      def table(path, page, strategy)
        run_json("table", path, page.to_s, strategy)
      end

      private

      def find_binary
        if (env = ENV["PDFSINK_BIN"]) && File.executable?(env)
          return env
        end

        gem_root = File.expand_path("../..", __dir__)

        candidates = [
          File.join(gem_root, "lib", "pdfsink", BINARY),
          File.join(gem_root, "ext", "pdfsink", "bin", BINARY),
        ]
        candidates.each { |path| return path if File.executable?(path) }

        # Fall back to PATH resolution at exec time.
        BINARY
      end

      def run(command, *args)
        argv = [binary, command, *args]
        stdout, stderr, status = Open3.capture3(*argv)

        unless status.success?
          raise CommandError.new(
            "pdfsink-rs #{command} failed: #{stderr.strip}",
            command: argv, status: status.exitstatus, stderr: stderr
          )
        end

        stdout
      rescue Errno::ENOENT
        raise BinaryNotFoundError,
              "Could not find the pdfsink-rs binary (looked for #{binary.inspect}).\n\n" \
              "Build it with:\n" \
              "  rake cargo:build\n\n" \
              "Or set PDFSINK_BIN to the full path of the binary."
      end

      def run_json(command, *args)
        out = run(command, *args)
        return nil if out.strip.empty?

        JSON.parse(out)
      rescue JSON::ParserError => e
        raise ParseError, "pdfsink-rs #{command} returned invalid JSON: #{e.message}"
      end
    end
  end
end
