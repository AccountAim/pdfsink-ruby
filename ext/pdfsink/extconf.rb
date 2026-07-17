# frozen_string_literal: true

# extconf.rb -- invoked by `gem install` or `bundle install` to build the
# pdfsink-rs CLI binary from the pinned git tag.
#
# Requirements:
#   - cargo / rustc (Rust toolchain, 1.97+)
#   - git
#
# Precompiled platform gems ship the binary in lib/pdfsink/ and strip this
# extension, so this script only runs for source installs.

require "fileutils"
# RubyGems runs this from the extension dir, so resolve the version from __dir__.
require File.expand_path("../../lib/pdfsink/version", __dir__)

CRATE     = "pdfsink-rs"
REPO      = "https://github.com/AccountAim/pdfsink-rs"
TAG       = "v#{Pdfsink::PDFSINK_RS_VERSION}"
BIN_NAME  = "pdfsink-rs"
EXT_DIR   = __dir__
LIB_DIR   = File.expand_path("../../lib/pdfsink", EXT_DIR)

def write_dummy_makefile
  File.write(File.join(EXT_DIR, "Makefile"), "all:\ninstall:\nclean:\n")
end

# ── Skip build if the binary already exists ───────────────────────────

if File.executable?(File.join(LIB_DIR, BIN_NAME))
  puts "#{BIN_NAME} already exists in #{LIB_DIR}, skipping Rust build."
  write_dummy_makefile
  exit 0
end

# ── Pre-flight checks ─────────────────────────────────────────────────

unless system("command -v cargo > /dev/null 2>&1")
  abort <<~MSG
    ERROR: `cargo` not found on PATH.

    The pdfsink gem requires the Rust toolchain to compile the native binary.
    Install Rust via https://rustup.rs and ensure `cargo` is on your PATH,
    then run `gem install pdfsink` again.
  MSG
end

# ── Build the binary into a staging root ──────────────────────────────

stage = File.join(EXT_DIR, "cargo-root")
FileUtils.mkdir_p(stage)

puts "Installing #{CRATE} #{TAG} from #{REPO} (release)..."
# Build from the git tag, not crates.io: the crate's [patch.crates-io] fix
# (vendored adobe-cmap-parser) is stripped on publish, so it only applies
# when building from source.
ok = system("cargo", "install", CRATE,
            "--git", REPO, "--tag", TAG,
            "--bin", BIN_NAME, "--locked",
            "--root", stage,
            "--force")
abort "ERROR: cargo install #{CRATE} failed" unless ok

# ── Copy the artifact into lib/pdfsink/ ───────────────────────────────

built = File.join(stage, "bin", BIN_NAME)
abort "ERROR: binary not found at #{built}" unless File.exist?(built)

FileUtils.mkdir_p(LIB_DIR)
dest = File.join(LIB_DIR, BIN_NAME)
FileUtils.cp(built, dest, verbose: true)
FileUtils.chmod(0o755, dest)
puts "Installed #{BIN_NAME} into #{LIB_DIR}"

write_dummy_makefile
