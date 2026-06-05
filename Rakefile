# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :cargo do
  desc "Build the pdfsink-rs binary into lib/pdfsink/"
  task :build do
    crate_ver = "0.2.8"
    bin_name  = "pdfsink-rs"
    stage     = File.expand_path("ext/pdfsink/cargo-root", __dir__)
    lib_dir   = File.expand_path("lib/pdfsink", __dir__)

    sh "cargo", "install", "pdfsink-rs",
       "--version", crate_ver, "--bin", bin_name,
       "--root", stage, "--force"

    built = File.join(stage, "bin", bin_name)
    abort "ERROR: binary not found at #{built}" unless File.exist?(built)

    mkdir_p lib_dir
    cp built, lib_dir, verbose: true
    chmod 0o755, File.join(lib_dir, bin_name)
  end
end

task default: :spec
