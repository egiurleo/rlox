# typed: strict
# frozen_string_literal: true

class Rlox
  class LoxClass
    include Callable

    #: String
    attr_reader :name

    #: (String) -> void
    def initialize(name)
      @name = name
    end

    # @override
    #: (Interpreter, Array[untyped]) -> untyped
    def call(interpreter, arguments)
      LoxInstance.new(self)
    end

    # @override
    #: () -> Integer
    def arity
      0
    end

    # @override
    #: () -> String
    def to_s
      @name
    end
  end

  class LoxInstance
    #: (LoxClass) -> void
    def initialize(klass)
      @klass = klass
      @fields = {} #: Hash[String, untyped]
    end

    #: (Token) -> untyped
    def get(name)
      return @fields.fetch(name.lexeme) if @fields.key?(name.lexeme)

      raise RuntimeError.new(name, "Undefined property '#{name.lexeme}'.")
    end

    #: (Token, untyped) -> void
    def set(name, value)
      @fields[name.lexeme] = value
    end

    # @override
    #: () -> String
    def to_s
      @klass.name + " instance"
    end
  end
end
