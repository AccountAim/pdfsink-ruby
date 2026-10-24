# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfsink::Page do
  describe "#tables" do
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
