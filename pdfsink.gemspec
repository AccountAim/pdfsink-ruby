# frozen_string_literal: true

require_relative "lib/pdfsink/version"

Gem::Specification.new do |spec|
  spec.name = "pdfsink"
  spec.version = Pdfsink::VERSION
  spec.authors = ["Accountaim"]
  spec.summary = "Ruby wrapper for pdfsink-rs: fast pure-Rust PDF extraction"
  spec.description = <<~DESC
    A Ruby gem that wraps the pdfsink-rs CLI, a fast pure-Rust PDF extraction
    tool, providing text, word, object, table, link, and regex-search
    extraction from PDFs for use in Rails applications.
  DESC
  spec.homepage = "https://github.com/AccountAim/pdfsink-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib,ext}/**/*", "Gemfile", "Rakefile", "pdfsink.gemspec", "LICENSE", "README.md"]
  end

  spec.require_paths = ["lib"]
  spec.extensions = ["ext/pdfsink/extconf.rb"]

  spec.metadata = {
    "source_code_uri" => "https://github.com/AccountAim/pdfsink-ruby",
    "rubygems_mfa_required" => "true"
  }
end
