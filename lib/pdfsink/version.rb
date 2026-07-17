# frozen_string_literal: true

module Pdfsink
  VERSION = "0.1.2"

  # Version of the pdfsink-rs crate this gem builds and wraps. Built from the
  # matching git tag (v#{PDFSINK_RS_VERSION}), not crates.io -- the crate carries
  # a [patch.crates-io] fix that cargo strips on publish.
  PDFSINK_RS_VERSION = "0.2.12"
end
