# typed: strict
# frozen_string_literal: true

class Rlox
  class Environment
    #: (?Environment?) -> void
    def initialize(enclosing = nil)
      @values = {} #: Hash[String, untyped]
      @enclosing = enclosing #: Environment?
    end

    #: (String, untyped) -> void
    def define(name, value)
      @values[name] = value
    end

    #: (Token) -> untyped
    def get(name)
      return @values[name.lexeme] if @values.key?(name.lexeme)
      return @enclosing.get(name) if @enclosing

      raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
    end

    #: (Token, Object) -> void
    def assign(name, value)
      if @values.key?(name.lexeme)
        @values[name.lexeme] = value
        return
      end

      if @enclosing
        @enclosing.assign(name, value)
        return
      end

      raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
    end
  end
end
