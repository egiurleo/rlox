# typed: strict
# frozen_string_literal: true

require 'rlox/token'

class Rlox
  # @abstract
  class Expr
    # @abstract
    #: [R] (Visitor[R]) -> R
    def accept(_visitor)
      raise 'Abstract method called'
    end

    # @abstract
    #: [R]
    module Visitor
      # @abstract
      #: (Assign) -> R
      def visit_assign_expr(_expr)
        raise 'Abstract method called'
      end

      # @abstract
      #: (Binary) -> R
      def visit_binary_expr(_expr)
        raise 'Abstract method called'
      end

      # @abstract
      #: (Call) -> R
      def visit_call_expr(_expr)
        raise 'Abstract method called'
      end

      # @abstract
      #: (Grouping) -> R
      def visit_grouping_expr(_expr)
        raise 'Abstract method called'
      end

      # @abstract
      #: (Literal) -> R
      def visit_literal_expr(_expr)
        raise 'Abstract method called'
      end

      # @abstract
      #: (Logical) -> R
      def visit_logical_expr(_expr)
        raise 'Abstract method called'
      end

      # @abstract
      #: (Unary) -> R
      def visit_unary_expr(_expr)
        raise 'Abstract method called'
      end

      # @abstract
      #: (Variable) -> R
      def visit_variable_expr(_expr)
        raise 'Abstract method called'
      end
    end
  end

  class Assign < Expr
    #: Token
    attr_reader :name

    #: Expr
    attr_reader :value

    #: (Token, Expr) -> void
    def initialize(name, value)
      super()
      @name = name
      @value = value
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_assign_expr(self)
    end
  end

  class Binary < Expr
    #: Expr
    attr_reader :left

    #: Token
    attr_reader :operator

    #: Expr
    attr_reader :right

    #: (Expr, Token, Expr) -> void
    def initialize(left, operator, right)
      super()
      @left = left
      @operator = operator
      @right = right
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_binary_expr(self)
    end
  end

  class Call < Expr
    #: Expr
    attr_reader :callee

    #: Token
    attr_reader :paren

    #: Array[Expr]
    attr_reader :arguments

    #: (Expr, Token, Array[Expr]) -> void
    def initialize(callee, paren, arguments)
      super()
      @callee = callee
      @paren = paren
      @arguments = arguments
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_call_expr(self)
    end
  end

  class Grouping < Expr
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
      visitor.visit_grouping_expr(self)
    end
  end

  class Literal < Expr
    #: untyped
    attr_reader :value

    #: (untyped) -> void
    def initialize(value)
      super()
      @value = value
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_literal_expr(self)
    end
  end

  class Logical < Expr
    #: Expr
    attr_reader :left

    #: Token
    attr_reader :operator

    #: Expr
    attr_reader :right

    #: (Expr, Token, Expr) -> void
    def initialize(left, operator, right)
      super()
      @left = left
      @operator = operator
      @right = right
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_logical_expr(self)
    end
  end

  class Unary < Expr
    #: Token
    attr_reader :operator

    #: Expr
    attr_reader :right

    #: (Token, Expr) -> void
    def initialize(operator, right)
      super()
      @operator = operator
      @right = right
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_unary_expr(self)
    end
  end

  class Variable < Expr
    #: Token
    attr_reader :name

    #: (Token) -> void
    def initialize(name)
      super()
      @name = name
    end

    # @override
    #: [R] (Visitor[R]) -> R
    def accept(visitor)
      visitor.visit_variable_expr(self)
    end
  end
end
