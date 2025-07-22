# typed: strict
# frozen_string_literal: true

class Rlox
  class ReturnError < StandardError
    #: untyped
    attr_reader :value

    #: (untyped, String) -> void
    def initialize(value, message)
      @value = value
      super(message)
    end
  end
end
