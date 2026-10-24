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

  describe "#load_all" do
    it "runs the program once and reads text and tables from memory" do
      expect(Pdfsink::Cli).to receive(:pages).once.and_call_original
      %i[info text table].each { |name| expect(Pdfsink::Cli).not_to receive(name) }

      doc.load_all
      doc.pages.each do |page|
        page.extract_text
        page.tables
      end
    end

    it "returns the pages" do
      pages = doc.load_all
      expect(pages.map(&:number)).to eq([1, 2])
      expect(pages.first).to equal(doc.page(1))
    end

    it "leaves info the same as the info command" do
      expected = Pdfsink::Cli.info(doc.path)
      doc.load_all
      expect(doc.info).to eq(expected)
    end

    %w[multipage.pdf table_lines.pdf].each do |name|
      it "matches single-page results for #{name}" do
        loaded = described_class.open(fixture(name))
        loaded.load_all

        loaded.pages.each do |page|
          expect(page.extract_text).to eq(Pdfsink::Cli.text(loaded.path, page.number))
          expect(page.tables).to eq(Pdfsink::Cli.table(loaded.path, page.number, "lines"))
        end
      end
    end

    it "stores tables only for the setting it loaded" do
      doc.load_all(strategy: :text)
      expect(Pdfsink::Cli).to receive(:table).with(doc.path, 1, "lines").once.and_call_original

      doc.page(1).tables(strategy: :text)
      doc.page(1).tables
    end

    it "fills pages created before it" do
      page = doc.page(1)
      doc.load_all
      expect(Pdfsink::Cli).not_to receive(:text)

      expect(doc.page(1)).to equal(page)
      expect(page.extract_text).to eq("Page One\n")
    end

    it "loads tables found with the given strategy" do
      loaded = described_class.open(fixture("table_lines.pdf"))
      expect(Pdfsink::Cli).to receive(:pages).with(loaded.path, "text").and_call_original
      loaded.load_all(strategy: :text)

      expect(loaded.page(1).tables(strategy: :text)).to eq(Pdfsink::Cli.table(loaded.path, 1, "text"))
    end

    it "raises a clear error when the binary has no pages command" do
      original = Pdfsink::Cli.binary
      Pdfsink::Cli.binary = "/bin/true"
      expect { doc.load_all }.to raise_error(Pdfsink::ParseError, /pages printed nothing/)
    ensure
      Pdfsink::Cli.binary = original
    end
  end
end
