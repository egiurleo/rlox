# typed: strict
# frozen_string_literal: true

require 'rlox/token'

class Rlox
  # @abstract
  class Stmt
    # @abstract
    #: [R] (Visitor[R]) -> R
    def accept(visitor); end

    # @abstract
    #: [R]
    module Visitor
      # @abstract
      #: (Block) -> R
      def visit_block_stmt(stmt); end

      # @abstract
      #: (Expression) -> R
      def visit_expression_stmt(stmt); end

      # @abstract
      #: (Print) -> R
      def visit_print_stmt(stmt); end

      # @abstract
      #: (Var) -> R
      def visit_var_stmt(stmt); end
    end
  end

  class Block < Stmt
    #: Array[Stmt]
    attr_reader :statements

    #: (Array[Stmt]) -> void
    def initialize(statements)
      super()
      @statements = statements
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_block_stmt(self)
    end
  end

  class Expression < Stmt
    #: Expr
    attr_reader :expression

    #: (Expr) -> void
    def initialize(expression)
      super()
      @expression = expression
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_expression_stmt(self)
    end
  end

  class Print < Stmt
    #: Expr
    attr_reader :expression

    #: (Expr) -> void
    def initialize(expression)
      super()
      @expression = expression
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_print_stmt(self)
    end
  end

  class Var < Stmt
    #: Token
    attr_reader :name

    #: Expr?
    attr_reader :initializer

    #: (Token, Expr?) -> void
    def initialize(name, initializer)
      super()
      @name = name
      @initializer = initializer
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_var_stmt(self)
    end
  end
end
