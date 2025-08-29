# typed: strict
# frozen_string_literal: true

require 'rlox/expr'
require 'rlox/stmt'
require 'rlox/runtime_error'
require 'rlox/return_error'
require 'rlox/environment'
require 'rlox/callable'
require 'rlox/lox_class'

class Rlox
  #: [R = untyped]
  class Interpreter
    include Expr::Visitor
    include Stmt::Visitor

    #: Environment
    attr_reader :globals

    #: () -> void
    def initialize
      @globals = Environment.new #: Environment
      @environment = @globals #: Environment
      @locals = {} #: Hash[Expr, Integer]

      @globals.define('clock', NativeClock.new)
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
    #: (Logical) -> untyped
    def visit_logical_expr(expr)
      left = evaluate(expr.left)
      if expr.operator.type == :OR
        return left if !!left # rubocop:disable Style/DoubleNegation
      else
        return left if !left # rubocop:disable Style/NegatedIf, Style/IfInsideElse
      end

      evaluate(expr.right)
    end

    # @override
    #: (Set) -> untyped
    def visit_set_expr(expr)
      object = evaluate(expr.object)

      raise RuntimeError.new(expr.name, 'Only instances have fields.') unless object.is_a?(LoxInstance)

      value = evaluate(expr.value)
      object.set(expr.name, value)

      value
    end

    # @override
    #: (This) -> untyped
    def visit_this_expr(expr)
      lookup_variable(expr.keyword, expr)
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
    #: (Call) -> void
    def visit_call_expr(expr)
      callee = evaluate(expr.callee)

      arguments = expr.arguments.map do |arg|
        evaluate(arg)
      end

      raise RuntimeError.new(expr.paren, 'Can only call functions and classes.') unless callee.is_a?(Callable)

      function = callee # as Callable

      if arguments.length != function.arity
        raise RuntimeError.new(expr.paren, "Expected #{function.arity} arguments but got #{arguments.size}.")
      end

      function.call(self, arguments)
    end

    # @override
    #: (Get) -> void
    def visit_get_expr(expr)
      object = evaluate(expr.object)
      return object.get(expr.name) if object.is_a?(LoxInstance)

      raise RuntimeError.new(expr.name, 'Only instances have properties.')
    end

    # @override
    #: (Expression) -> void
    def visit_expression_stmt(stmt)
      evaluate(stmt.expression)
    end

    # @override
    #: (Function) -> void
    def visit_function_stmt(stmt)
      function = LoxFunction.new(stmt, @environment, false)
      @environment.define(stmt.name.lexeme, function)
    end

    # @override
    #: (If) -> void
    def visit_if_stmt(stmt)
      else_branch = stmt.else_branch

      if evaluate(stmt.condition)
        execute(stmt.then_branch)
      elsif else_branch
        execute(else_branch)
      end
    end

    # @override
    #: (Print) -> void
    def visit_print_stmt(stmt)
      value = evaluate(stmt.expression)
      puts(value)
    end

    # @override
    #: (Return) -> void
    def visit_return_stmt(stmt)
      stmt_value = stmt.value

      value = nil
      value = evaluate(stmt_value) if stmt_value

      raise ReturnError.new(value, '')
    end

    # @override
    #: (Var) -> void
    def visit_var_stmt(stmt)
      initializer = stmt.initializer
      value = initializer.nil? ? nil : evaluate(initializer)

      @environment.define(stmt.name.lexeme, value)
    end

    # @override
    #: (While) -> void
    def visit_while_stmt(stmt)
      execute(stmt.body) while evaluate(stmt.condition)
    end

    # @override
    #: (Assign) -> untyped
    def visit_assign_expr(expr)
      value = evaluate(expr.value)

      distance = @locals[expr]

      if distance
        @environment.assign_at(distance, expr.name, value)
      else
        @globals.assign(expr.name, value)
      end

      @environment.assign(expr.name, value)

      value
    end

    # @override
    #: (Variable) -> untyped
    def visit_variable_expr(expr)
      lookup_variable(expr.name, expr)
    end

    # @override
    #: (Block) -> void
    def visit_block_stmt(stmt)
      execute_block(stmt.statements, Environment.new(@environment))
    end

    # @override
    #: (Class) -> void
    def visit_class_stmt(stmt)
      @environment.define(stmt.name.lexeme, nil)

      methods = {} #: Hash[String, LoxFunction]
      stmt.methods.each do |method|
        function = LoxFunction.new(method, @environment, method.name.lexeme == 'init')
        methods[method.name.lexeme] = function
      end

      klass = LoxClass.new(stmt.name.lexeme, methods)
      @environment.assign(stmt.name, klass)
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

    #: (Expr, Integer) -> void
    def resolve(expr, depth)
      @locals[expr] = depth
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

    #: (Token, Expr) -> untyped
    def lookup_variable(name, expr)
      distance = @locals[expr]

      return @environment.get_at(distance, name.lexeme) if distance

      @globals.get(name)
    end
  end
end
