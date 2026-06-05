# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfsink::Document do
  let(:doc) { described_class.open(fixture("multipage.pdf")) }

  describe "#page_count" do
    it "reports the number of pages" do
      expect(doc.page_count).to eq(2)
    end
  end

  describe "#page" do
    it "returns a Page with metadata from info" do
      page = doc.page(1)
      expect(page).to be_a(Pdfsink::Page)
      expect(page.number).to eq(1)
      expect(page.width).to be > 0
      expect(page.height).to be > 0
      expect(page.bbox).to include("x0", "top", "x1", "bottom")
    end

    it "memoizes pages" do
      expect(doc.page(1)).to equal(doc.page(1))
    end

    it "raises on out-of-range pages" do
      expect { doc.page(0) }.to raise_error(RangeError)
      expect { doc.page(99) }.to raise_error(RangeError)
    end
  end

  describe "#pages / #each_page" do
    it "yields every page" do
      expect(doc.pages.map(&:number)).to eq([1, 2])
      expect(doc.each_page.to_a.size).to eq(2)
    end
  end
end

RSpec.describe Pdfsink::Page do
  describe "#extract_text" do
    it "returns the page text" do
      page = Pdfsink.open(fixture("simple_text.pdf")).page(1)
      expect(page.extract_text).to be_a(String).and(satisfy { |t| !t.empty? })
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
  end
end
