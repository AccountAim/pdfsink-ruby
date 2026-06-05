# frozen_string_literal: true

module Pdfsink
  # Base error for all Pdfsink errors.
  class Error < StandardError; end

  # Raised when the pdfsink-rs binary cannot be located.
  class BinaryNotFoundError < Error; end

  # Raised when the pdfsink-rs binary exits non-zero.
  #
  # Carries the failing command, exit status, and captured stderr.
  class CommandError < Error
    # @return [Array<String>] the argv that was executed
    attr_reader :command

    # @return [Integer, nil] the process exit status
    attr_reader :status

    # @return [String] captured standard error
    attr_reader :stderr

    def initialize(message, command:, status:, stderr:)
      @command = command
      @status  = status
      @stderr  = stderr
      super(message)
    end
  end

  # Raised when the binary's stdout is not the JSON we expected.
  class ParseError < Error; end
end
