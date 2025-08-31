# typed: strict
# frozen_string_literal: true

class Rlox
  class LoxClass
    include Callable

    #: String
    attr_reader :name

    #: (String, LoxClass?, Hash[String, LoxFunction]) -> void
    def initialize(name, superclass, methods)
      @name = name
      @methods = methods
      @superclass = superclass
    end

    #: (String) -> LoxFunction?
    def find_method(name)
      return @methods[name] if @methods.key?(name)

      @superclass&.find_method(name)
    end

    # @override
    #: (Interpreter, Array[untyped]) -> untyped
    def call(interpreter, arguments)
      instance = LoxInstance.new(self)
      initializer = find_method('init')

      return unless initializer

      initializer.bind(instance).call(interpreter, arguments)
    end

    # @override
    #: () -> Integer
    def arity
      initializer = find_method('init')
      return 0 unless initializer

      initializer.arity
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

      method = @klass.find_method(name.lexeme)
      return method.bind(self) if method

      raise RuntimeError.new(name, "Undefined property '#{name.lexeme}'.")
    end

    #: (Token, untyped) -> void
    def set(name, value)
      @fields[name.lexeme] = value
    end

    # @override
    #: () -> String
    def to_s
      "#{@klass.name} instance"
    end
  end
end
