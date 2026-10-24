# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfsink::Page do
  describe "#extract_text" do
    it "returns the page text" do
      page = Pdfsink.open(fixture("simple_text.pdf")).page(1)
      expect(page.extract_text).to be_a(String).and(satisfy { |t| !t.empty? })
    end

    it "returns UTF-8 text under a non-UTF-8 locale" do
      page = Pdfsink.open(fixture("simple_text.pdf")).page(1)
      with_default_external(Encoding::US_ASCII) do
        expect(page.extract_text.encoding).to eq(Encoding::UTF_8)
      end
    end
  end

  describe "#extract_words" do
    it "returns words with positions" do
      words = Pdfsink.open(fixture("simple_text.pdf")).page(1).extract_words
      expect(words).to be_an(Array)
      expect(words.first).to include("text")
    end
  end

  describe "#objects" do
    it "returns a dict of page objects" do
      objects = Pdfsink.open(fixture("objects_showcase.pdf")).page(1).objects
      expect(objects).to be_a(Hash)
    end
  end

  describe "#tables" do
    it "extracts a ruled table" do
      table = Pdfsink.open(fixture("table_lines.pdf")).page(1).tables(strategy: :lines)
      expect(table).to be_an(Array)
      expect(table.first).to eq(%w[Name Age City])
    end

    it "runs the program once for each table setting" do
      doc = Pdfsink.open(fixture("table_lines.pdf"))
      page = doc.page(1)
      expect(Pdfsink::Cli).to receive(:table).with(doc.path, 1, "lines").once.and_call_original
      expect(Pdfsink::Cli).to receive(:table).with(doc.path, 1, "text").once.and_call_original

      2.times do
        page.tables
        page.tables(strategy: :text)
      end
    end

    it "stores a result of no table" do
      page = Pdfsink.open(fixture("simple_text.pdf")).page(1)
      expect(Pdfsink::Cli).to receive(:table).once.and_call_original

      2.times { expect(page.tables).to be_nil }
    end
  end
end
