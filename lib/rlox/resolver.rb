# typed: strict
# frozen_string_literal: true

require 'debug'

class Rlox
  #: [R = void]
  class Resolver
    include Expr::Visitor
    include Stmt::Visitor

    FUNCTION_TYPES = %i[NONE FUNCTION METHOD INITIALIZER].freeze
    CLASS_TYPES = %i[NONE CLASS].freeze

    #: (Interpreter) -> void
    def initialize(interpreter)
      @interpreter = interpreter
      @scopes = [] #: Array[Hash[String, bool]]
      @current_function = :NONE #: Symbol
      @current_class = :NONE #: Symbol
    end

    # @override
    #: (Block) -> void
    def visit_block_stmt(stmt)
      begin_scope
      resolve(stmt.statements)
      end_scope
    end

    # @override
    #: (Class) -> void
    def visit_class_stmt(stmt)
      enclosing_class = @current_class
      @current_class = :CLASS

      declare(stmt.name)
      define(stmt.name)

      begin_scope
      innermost_scope = @scopes.last #: as Hash[String, bool]
      innermost_scope['this'] = true

      stmt.methods.each do |method|
        declaration = :METHOD
        declaration = :INITIALIZER if method.name.lexeme == 'init'

        resolve_function(method, declaration)
      end

      end_scope
      @current_class = enclosing_class
    end

    # @override
    #: (Var) -> void
    def visit_var_stmt(stmt)
      declare(stmt.name)

      initializer = stmt.initializer
      resolve(initializer) if initializer

      define(stmt.name)
    end

    # @override
    #: (Variable) -> void
    def visit_variable_expr(expr)
      if !@scopes.empty? && @scopes.last&.dig(expr.name.lexeme) == false
        Rlox.error(expr.name, "Can't read local variable in its own initializer.")
      end

      resolve_local(expr, expr.name)
    end

    # @override
    #: (Assign) -> void
    def visit_assign_expr(expr)
      resolve(expr.value)
      resolve_local(expr, expr.name)
    end

    # @override
    #: (Function) -> void
    def visit_function_stmt(stmt)
      declare(stmt.name)
      define(stmt.name)

      resolve_function(stmt, :FUNCTION)
    end

    # @override
    #: (Expression) -> void
    def visit_expression_stmt(stmt)
      resolve(stmt.expression)
    end

    # @override
    #: (If) -> void
    def visit_if_stmt(stmt)
      resolve(stmt.condition)
      resolve(stmt.then_branch)

      else_branch = stmt.else_branch
      resolve(else_branch) if else_branch
    end

    # @override
    #: (Print) -> void
    def visit_print_stmt(stmt)
      resolve(stmt.expression)
    end

    # @override
    #: (Return) -> void
    def visit_return_stmt(stmt)
      Rlox.error(stmt.keyword, "Can't return from top-level code.") if @current_function == :NONE

      value = stmt.value
      return unless value

      Rlox.error(stmt.keyword, "Can't return a value from an initializer.") if @current_function == :INITIALIZER
      resolve(value)
    end

    # @override
    #: (While) -> void
    def visit_while_stmt(stmt)
      resolve(stmt.condition)
      resolve(stmt.body)
    end

    # @override
    #: (Binary) -> void
    def visit_binary_expr(expr)
      resolve(expr.left)
      resolve(expr.right)
    end

    # @override
    #: (Call) -> void
    def visit_call_expr(expr)
      resolve(expr.callee)

      expr.arguments.each do |argument|
        resolve(argument)
      end
    end

    # @override
    #: (Get) -> void
    def visit_get_expr(expr)
      resolve(expr.object)
    end

    # @override
    #: (Grouping) -> void
    def visit_grouping_expr(expr)
      resolve(expr.expression)
    end

    # @override
    #: (Literal) -> void
    def visit_literal_expr(expr); end

    # @override
    #: (Logical) -> void
    def visit_logical_expr(expr)
      resolve(expr.left)
      resolve(expr.right)
    end

    # @override
    #: (Set) -> void
    def visit_set_expr(expr)
      resolve(expr.value)
      resolve(expr.object)
    end

    # @override
    #: (This) -> void
    def visit_this_expr(expr)
      if @current_class == :NONE
        Rlox.error(expr.keyword, "Can't use 'this' outside of a class.")
        return
      end

      resolve_local(expr, expr.keyword)
    end

    # @override
    #: (Unary) -> void
    def visit_unary_expr(expr)
      resolve(expr.right)
    end

    #: (Array[Stmt] | Stmt | Expr ) -> void
    def resolve(statements)
      if statements.is_a?(Array)
        statements.each do |statement|
          resolve(statement)
        end
      else
        statements.accept(self)
      end
    end

    private

    #: () -> void
    def begin_scope
      @scopes.push({})
    end

    #: () -> void
    def end_scope
      @scopes.pop
    end

    #: (Token) -> void
    def declare(name)
      return if @scopes.empty?

      scope = @scopes.last #: as Hash[String, bool]

      Rlox.error(name, 'Already a variable with this name in this scope.') if scope.key?(name.lexeme)

      scope[name.lexeme] = false
    end

    #: (Token) -> void
    def define(name)
      return if @scopes.empty?

      scope = @scopes.last #: as Hash[String, bool]
      scope[name.lexeme] = true
    end

    #: (Expr, Token) -> void
    def resolve_local(expr, name)
      (0...@scopes.length).reverse_each do |i|
        scope = @scopes[i] #: as Hash[String, bool]
        if scope.key?(name.lexeme)
          @interpreter.resolve(expr, @scopes.length - 1 - i)
          break
        end
      end
    end

    #: (Function, Symbol) -> void
    def resolve_function(function, type)
      check_function_type!(type)

      enclosing_function = @current_function
      @current_function = type

      begin_scope

      function.params.each do |param|
        declare(param)
        define(param)
      end

      resolve(function.body)
      end_scope
      @current_function = enclosing_function
    end

    #: (Symbol) -> void
    def check_function_type!(type)
      raise unless FUNCTION_TYPES.include?(type)
    end
  end
end
