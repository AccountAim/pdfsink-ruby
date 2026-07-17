# frozen_string_literal: true

require "rspec/core/rake_task"
require "./lib/pdfsink/version"

RSpec::Core::RakeTask.new(:spec)

namespace :cargo do
  desc "Build the pdfsink-rs binary into lib/pdfsink/"
  task :build do
    bin_name = "pdfsink-rs"
    repo     = "https://github.com/AccountAim/pdfsink-rs"
    tag      = "v#{Pdfsink::PDFSINK_RS_VERSION}"
    stage    = File.expand_path("ext/pdfsink/cargo-root", __dir__)
    lib_dir  = File.expand_path("lib/pdfsink", __dir__)

    # Build from the pinned git tag, not crates.io: the crate carries a
    # [patch.crates-io] for a vendored adobe-cmap-parser fix, and cargo strips
    # [patch] on publish -- so the fix only applies when building from source.
    sh "cargo", "install", "pdfsink-rs",
       "--git", repo, "--tag", tag,
       "--bin", bin_name, "--locked",
       "--root", stage, "--force"

    built = File.join(stage, "bin", bin_name)
    abort "ERROR: binary not found at #{built}" unless File.exist?(built)

    mkdir_p lib_dir
    cp built, lib_dir, verbose: true
    chmod 0o755, File.join(lib_dir, bin_name)
  end
end

task default: :spec
