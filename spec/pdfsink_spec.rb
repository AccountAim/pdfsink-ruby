# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfsink do
  describe ".version" do
    it "returns a semver string" do
      expect(Pdfsink.version).to match(/\A\d+\.\d+\.\d+/)
    end
  end

  describe ".open" do
    it "returns a Document" do
      expect(Pdfsink.open(fixture("simple_text.pdf"))).to be_a(Pdfsink::Document)
    end

    it "raises if the file is missing" do
      expect { Pdfsink.open("/no/such.pdf") }.to raise_error(Errno::ENOENT)
    end
  end

  describe ".extract_text" do
    it "extracts text from a page" do
      text = Pdfsink.extract_text(fixture("simple_text.pdf"), page: 1)
      expect(text).to be_a(String)
      expect(text).not_to be_empty
    end
  end

  describe Pdfsink::TableStrategy do
    it "resolves symbols and strings" do
      expect(described_class.resolve(:text)).to eq("text")
      expect(described_class.resolve("LINES")).to eq("lines")
    end

    it "defaults to lines" do
      expect(described_class.resolve(nil)).to eq("lines")
    end

    it "raises on unknown strategies" do
      expect { described_class.resolve(:nope) }.to raise_error(ArgumentError)
    end

    it "honors the configured default" do
      Pdfsink.configure { |c| c.default_table_strategy = :text }
      expect(described_class.resolve(nil)).to eq("text")
    ensure
      Pdfsink.configuration.default_table_strategy = nil
    end
  end

  describe Pdfsink::CommandError do
    it "is raised on a bad page request via the CLI" do
      doc = Pdfsink.open(fixture("simple_text.pdf"))
      expect { Pdfsink::Cli.text(doc.path, 99) }.to raise_error(Pdfsink::CommandError)
    end
  end
end
