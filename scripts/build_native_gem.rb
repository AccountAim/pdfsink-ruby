# frozen_string_literal: true

# Build a platform-specific gem that includes a precompiled pdfsink-rs binary.
#
# Usage:
#   ruby scripts/build_native_gem.rb PLATFORM
#
# Example:
#   ruby scripts/build_native_gem.rb arm64-darwin
#
# The precompiled binary (lib/pdfsink/pdfsink-rs) must already be present
# before running this script. The resulting .gem is written to pkg/.

require "rubygems"
require "rubygems/package"
require "fileutils"

platform = ARGV[0]
abort "Usage: #{$0} PLATFORM\n\nExample: #{$0} arm64-darwin" unless platform

gemspec_path = File.expand_path("../pdfsink.gemspec", __dir__)
abort "ERROR: gemspec not found at #{gemspec_path}" unless File.exist?(gemspec_path)

lib_dir = File.expand_path("../lib/pdfsink", __dir__)
binary  = File.join(lib_dir, "pdfsink-rs")
abort "ERROR: precompiled binary not found at #{binary}" unless File.exist?(binary)

# The exec bit must survive into the gem's tar entry.
FileUtils.chmod(0o755, binary)

spec = Gem::Specification.load(gemspec_path)

# Target platform (e.g. "x86_64-linux", "arm64-darwin").
spec.platform = Gem::Platform.new(platform)

# Drop the extension -- the binary is already bundled, so no toolchain runs.
spec.extensions = []

# Ensure the binary is in the file list.
relative = "lib/pdfsink/pdfsink-rs"
spec.files << relative unless spec.files.include?(relative)

FileUtils.mkdir_p("pkg")
gem_file = Gem::Package.build(spec)
FileUtils.mv(gem_file, "pkg/")

puts "Built pkg/#{File.basename(gem_file)}"
