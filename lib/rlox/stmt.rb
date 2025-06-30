# typed: strict
# frozen_string_literal: true

require 'rlox/token'

class Rlox
  # @abstract
  class Stmt
    # @abstract
    #: [R] (Visitor[R]) -> R
    def accept(_visitor)
      raise 'Abstract method called'
    end

    # @abstract
    #: [R]
    module Visitor
      # @abstract
      #: (Block) -> R
      def visit_block_stmt(_stmt)
        raise 'Abstract method called'
      end

      # @abstract
      #: (Expression) -> R
      def visit_expression_stmt(_stmt)
        raise 'Abstract method called'
      end

      # @abstract
      #: (If) -> R
      def visit_if_stmt(_stmt)
        raise 'Abstract method called'
      end

      # @abstract
      #: (Print) -> R
      def visit_print_stmt(_stmt)
        raise 'Abstract method called'
      end

      # @abstract
      #: (Var) -> R
      def visit_var_stmt(_stmt)
        raise 'Abstract method called'
      end

      # @abstract
      #: (While) -> R
      def visit_while_stmt(_stmt)
        raise 'Abstract method called'
      end
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

  class If < Stmt
    #: Expr
    attr_reader :condition

    #: Stmt
    attr_reader :then_branch

    #: Stmt?
    attr_reader :else_branch

    #: (Expr, Stmt, Stmt?) -> void
    def initialize(condition, then_branch, else_branch)
      super()
      @condition = condition
      @then_branch = then_branch
      @else_branch = else_branch
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_if_stmt(self)
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

  class While < Stmt
    #: Expr
    attr_reader :condition

    #: Stmt
    attr_reader :body

    #: (Expr, Stmt) -> void
    def initialize(condition, body)
      super()
      @condition = condition
      @body = body
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_while_stmt(self)
    end
  end
end
