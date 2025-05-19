# typed: strict
# frozen_string_literal: true

require 'rlox/expr'
require 'rlox/runtime_error'

class Rlox
  #: [R = untyped]
  class Interpreter < Expr::Visitor
    #: (Expr) -> void
    def interpret(expression)
      value = evaluate(expression)
      puts value
    rescue RuntimeError => e
      Rlox.runtime_error(e)
    end

    # @override
    #: (Literal) -> untyped
    def visit_literal_expr(expr)
      expr.value
    end

    # @override
    #: (Grouping) -> untyped
    def visit_grouping_expr(expr)
      evaluate(expr.expression)
    end

    # @override
    #: (Unary) -> untyped
    def visit_unary_expr(expr)
      right = evaluate(expr.right)

      case expr.operator.type
      when :MINUS
        check_number_operand!(expr.operator, right)
        -1.0 * right
      when :BANG then !truthy?(right)
      end

      # Implictly returns nil if no case is matched
    end

    # @override
    #: (Binary) -> untyped
    def visit_binary_expr(expr)
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.operator.type
      when :BANG_EQUAL    then left != right
      when :EQUAL_EQUAL   then left == right
      when :MINUS
        check_number_operands!(expr.operator, right, left)
        left - right
      when :SLASH
        check_number_operands!(expr.operator, right, left)
        left / right
      when :STAR
        check_number_operands!(expr.operator, right, left)
        left * right
      when :GREATER
        check_number_operands!(expr.operator, right, left)
        left > right
      when :GREATER_EQUAL
        check_number_operands!(expr.operator, right, left)
        left >= right
      when :LESS
        check_number_operands!(expr.operator, right, left)
        left < right
      when :LESS_EQUAL
        check_number_operands!(expr.operator, right, left)
        left <= right
      when :PLUS
        return left + right if left.is_a?(Float) && right.is_a?(Float)
        return left + right if left.is_a?(String) && right.is_a?(String)

        raise RuntimeError.new(expr.operator, 'Operands must be two numbers or two strings.')
      end

      # Implictly returns nil if no case is matched
    end

    private

    #: (Expr) -> untyped
    def evaluate(expr)
      expr.accept(self)
    end

    #: (untyped) -> bool
    def truthy?(obj)
      !!obj # Lox follows Ruby's truthiness/falsiness pattern
    end

    #: (Token, untyped) -> void
    def check_number_operand!(operator, operand)
      return if operand.is_a?(Float)

      raise RuntimeError.new(operator, 'Operand must be a number.')
    end

    #: (Token, untyped, untyped) -> void
    def check_number_operands!(operator, left, right)
      return if left.is_a?(Float) && right.is_a?(Float)

      raise RuntimeError.new(operator, 'Operands must be numbers.')
    end
  end
end
