# typed: strict
# frozen_string_literal: true

class Rlox
  class Environment
    #: Environment?
    attr_reader :enclosing

    #: Hash[String, untyped]
    attr_reader :values

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

    #: (Integer, String) -> untyped
    def get_at(distance, name)
      ancestor(distance).values[name]
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

    #: (Integer, Token, Object) -> void
    def assign_at(distance, name, value)
      ancestor(distance).values[name.lexeme] = value
    end

    private

    #: (Integer) -> Environment
    def ancestor(distance)
      environment = self

      distance.times do
        environment = environment.enclosing #: as Environment
      end

      environment
    end
  end
end
