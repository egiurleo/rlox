# typed: strict
# frozen_string_literal: true

require 'rlox/expr'
require 'rlox/stmt'
require 'rlox/runtime_error'
require 'rlox/environment'

class Rlox
  #: [R = untyped]
  class Interpreter
    include Expr::Visitor
    include Stmt::Visitor

    #: () -> void
    def initialize
      @environment = Environment.new #: Environment
    end

    #: (Array[Stmt]) -> void
    def interpret(statements)
      statements.each do |statement|
        execute(statement)
      end
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

    # @override
    #: (Expression) -> void
    def visit_expression_stmt(stmt)
      evaluate(stmt.expression)
    end

    # @override
    #: (Print) -> void
    def visit_print_stmt(stmt)
      value = evaluate(stmt.expression)
      puts(value)
    end

    # @override
    #: (Var) -> void
    def visit_var_stmt(stmt)
      initializer = stmt.initializer
      value = initializer.nil? ? nil : evaluate(initializer)

      @environment.define(stmt.name.lexeme, value)
    end

    # @override
    #: (Assign) -> untyped
    def visit_assign_expr(expr)
      value = evaluate(expr.value)
      @environment.assign(expr.name, value)

      value
    end

    # @override
    #: (Variable) -> untyped
    def visit_variable_expr(expr)
      @environment.get(expr.name)
    end

    # @override
    #: (Block) -> void
    def visit_block_stmt(stmt)
      execute_block(stmt.statements, Environment.new(@environment))
    end

    #: (Array[Stmt], Environment) -> void
    def execute_block(statements, environment)
      previous = @environment

      @environment = environment

      statements.each do |statement|
        execute(statement)
      end
    ensure
      @environment = previous if previous
    end

    #: (Stmt) -> void
    def execute(stmt)
      stmt.accept(self)
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
