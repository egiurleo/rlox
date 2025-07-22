# typed: strict
# frozen_string_literal: true

require 'rlox/interpreter'
require 'rlox/stmt'

class Rlox
  # @interface
  module Callable
    # @abstract
    #: -> Integer
    def arity
      raise NotImplementedError
    end

    # @abstract
    #: (Interpreter, Array[untyped]) -> untyped
    def call(interpreter, arguments)
      raise NotImplementedError
    end
  end

  class LoxFunction
    include Callable

    #: (Function, Environment) -> void
    def initialize(declaration, closure)
      @declaration = declaration
      @closure = closure
    end

    # @override
    #: (Interpreter, Array[untyped]) -> untyped
    def call(interpreter, arguments)
      environment = Environment.new(@closure)

      @declaration.params.each_with_index do |param, idx|
        environment.define(param.lexeme, arguments[idx])
      end

      begin
        interpreter.execute_block(@declaration.body, environment)
      rescue ReturnError => e
        e.value
      end
    end

    # @override
    #: -> Integer
    def arity
      @declaration.params.length
    end

    #: -> String
    def to_s
      "<fn #{@declaration.name.lexeme}>"
    end
  end

  class NativeClock
    include Callable

    # @override
    #: -> Integer
    def arity
      0
    end

    # @override
    #: (Interpreter, Array[untyped]) -> untyped
    def call(_interpreter, _arguments)
      Time.now.to_f
    end

    # @override
    #: -> String
    def to_s
      '<native fn>'
    end
  end
end
