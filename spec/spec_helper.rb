# frozen_string_literal: true

require "pdfsink"

FIXTURES = File.expand_path("fixtures", __dir__)

def fixture(name)
  File.join(FIXTURES, name)
end

# Run the block as if the process locale used +encoding+. Ruby warns when
# Encoding.default_external is set, so the warning is silenced for the change.
def with_default_external(encoding)
  original = Encoding.default_external
  set_default_external(encoding)
  yield
ensure
  set_default_external(original)
end

def set_default_external(encoding)
  verbose = $VERBOSE
  $VERBOSE = nil
  Encoding.default_external = encoding
ensure
  $VERBOSE = verbose
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end
