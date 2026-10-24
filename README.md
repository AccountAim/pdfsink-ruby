# Pdfsink

Ruby wrapper for [pdfsink-rs](https://github.com/clark-labs-inc/pdfsink-rs), a
fast pure-Rust PDF extraction tool. Extract text, words, page objects, tables,
hyperlinks, and regex matches from PDFs — without a Python runtime.

The gem shells out to the bundled `pdfsink-rs` binary and parses its JSON
output, so there is nothing to load into your Ruby process and no FFI.

## Requirements

- Ruby >= 3.2
- For source installs only: a Rust toolchain (`cargo`) to compile the binary.
  Precompiled platform gems bundle the binary and need no toolchain.

## Installation

```ruby
# Gemfile
gem "pdfsink"
```

```bash
bundle install
# or
gem install pdfsink
```

On supported platforms (`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`,
`arm64-darwin`) a precompiled gem ships the binary. Elsewhere the source gem
compiles it on install via `cargo install pdfsink-rs`.

### Building from source

```bash
git clone https://github.com/AccountAim/pdfsink-ruby
cd pdfsink-ruby
bundle install
bundle exec rake cargo:build   # compiles the binary into lib/pdfsink/
bundle exec rspec
```

To point the gem at a binary you built elsewhere, set `PDFSINK_BIN`:

```bash
export PDFSINK_BIN=/path/to/pdfsink-rs
```

## Usage

### Open a document

```ruby
doc = Pdfsink.open("report.pdf")
doc.page_count        # => 12
doc.pages             # => [#<Pdfsink::Page number=1 612.0x792.0>, ...]
doc.each_page { |page| puts page.extract_text }
```

### Extract text

```ruby
page = doc.page(1)
page.extract_text     # => "Quarterly Report\n..."

# One-shot, without holding a Document:
Pdfsink.extract_text("report.pdf", page: 1)
```

### Words with positions

```ruby
page.extract_words
# => [{"text" => "Quarterly", "x0" => 72.0, "top" => 90.1, ...}, ...]
```

### Page objects

```ruby
page.object_counts    # => {"chars" => 812, "lines" => 14, "rects" => 3, ...}
page.objects          # => {"chars" => [...], "lines" => [...], ...}
```

### Tables

```ruby
page.tables                      # default strategy ("lines")
page.tables(strategy: :text)     # infer from text alignment
# => [["Name", "Age", "City"], ["Alice", "31", "Oakland"], ...]
```

Strategies: `:lines`, `:lines_strict`, `:text`, `:explicit`
(see `Pdfsink::TableStrategy`).

### Hyperlinks

```ruby
page.links
# => [{"uri" => "https://example.com", "x0" => 72.0, ...}]
```

### Search

```ruby
page.search(/total:\s*\$\d+/i)
# => [{"text" => "Total: $420", "x0" => ..., ...}]
```

### Read every page in one run

Each page method runs the pdfsink-rs binary for that page only. To read
every page, `load_all` runs it once for the whole document:

```ruby
doc = Pdfsink.open("report.pdf")
doc.load_all                     # one run; returns doc.pages
doc.pages.each do |page|
  page.extract_text              # no further runs
  page.tables                    # no further runs (same strategy as load_all)
end

doc.load_all(strategy: :text)    # load tables found with another strategy
```

Use the page methods when you need a few pages, and `load_all` when you
need all of them. `load_all` loads text and tables only; `extract_words`,
`objects`, `links` and `search` still run the binary for their page.

### Binary version

```ruby
Pdfsink.version   # => "0.2.20+aim.1"
```

## Rails Integration

```ruby
# config/application.rb (or an initializer)
config.pdfsink.default_table_strategy = :text
config.pdfsink.binary_path = Rails.root.join("bin/pdfsink-rs").to_s
```

## Configuration

```ruby
Pdfsink.configure do |config|
  config.default_table_strategy = :text   # used when Page#tables gets no strategy
end
```

The binary is located in this order:

1. `PDFSINK_BIN` environment variable
2. `lib/pdfsink/pdfsink-rs` inside the gem (bundled / built)
3. `ext/pdfsink/bin/pdfsink-rs` (dev location)
4. `pdfsink-rs` on `PATH`

## Development

```bash
bundle install
bundle exec rake cargo:build
bundle exec rspec
```

## License

MIT — see [LICENSE](LICENSE).
