# typed: strict
# frozen_string_literal: true

require 'rlox/token'
require 'rlox/expr'
require 'rlox/stmt'

class Rlox
  class Parser
    class ParseError < StandardError; end

    #: (Array[Token]) -> void
    def initialize(tokens)
      @tokens = tokens
      @current = 0 #: Integer
    end

    #: () -> Array[Stmt]
    def parse
      statements = []
      statements << declaration until at_end?
      statements
    end

    private

    #: () -> Expr
    def expression
      assignment
    end

    #: () -> Stmt
    def statement
      return for_statement    if match?(:FOR)
      return if_statement     if match?(:IF)
      return print_statement  if match?(:PRINT)
      return return_statement if match?(:RETURN)
      return while_statement  if match?(:WHILE)
      return Block.new(block) if match?(:LEFT_BRACE)

      expression_statement
    end

    #: () -> Stmt
    def for_statement
      consume(:LEFT_PAREN, "Expect '(' after 'for'.")

      initializer = if match?(:SEMICOLON)
                      nil
                    elsif match?(:VAR)
                      var_declaration
                    else
                      expression_statement
                    end

      condition = if check?(:SEMICOLON)
                    Literal.new(true)
                  else
                    expression
                  end

      consume(:SEMICOLON, "Expect ';' after loop condition.")

      increment = if check?(:RIGHT_PAREN)
                    nil
                  else
                    expression
                  end

      consume(:RIGHT_PAREN, "Expect ')' after for clauses.")

      body = statement

      body = Block.new([body, Expression.new(increment)]) unless increment.nil?
      body = While.new(condition, body)
      body = Block.new([initializer, body]) unless initializer.nil?

      body
    end

    #: () -> Stmt
    def if_statement
      consume(:LEFT_PAREN, "Expect '(' after 'if'.")
      condition = expression
      consume(:RIGHT_PAREN, "Expect ')' after condition.")

      then_branch = statement
      else_branch = nil
      else_branch = statement if match?(:ELSE)

      If.new(condition, then_branch, else_branch)
    end

    #: () -> Stmt?
    def declaration
      return function('function') if match?(:FUN)
      return var_declaration if match?(:VAR)

      statement
    rescue ParseError
      synchronize
      nil
    end

    #: () -> Stmt
    def var_declaration
      name = consume(:IDENTIFIER, 'Expect variable name.')
      initializer = match?(:EQUAL) ? expression : nil
      consume(:SEMICOLON, "Expect ';' after variable declaration")
      Var.new(name, initializer)
    end

    #: () -> Stmt
    def while_statement
      consume(:LEFT_PAREN, "Expect '(' after 'while'.")
      condition = expression
      consume(:RIGHT_PAREN, "Expect ')' after 'while'.")
      body = statement

      While.new(condition, body)
    end

    #: () -> Stmt
    def print_statement
      value = expression
      consume(:SEMICOLON, "Expect ';' after value.")
      Print.new(value)
    end

    #: () -> Stmt
    def return_statement
      keyword = previous

      value = nil
      value = expression unless check?(:SEMICOLON)

      consume(:SEMICOLON, "Expect ';' after return value.")
      Return.new(keyword, value)
    end

    #: () -> Stmt
    def expression_statement
      expr = expression
      consume(:SEMICOLON, "Expect ';' after expression.")
      Expression.new(expr)
    end

    #: (String) -> Function
    def function(kind)
      name = consume(:IDENTIFIER, "Expect #{kind} name.")
      consume(:LEFT_PAREN, "Expect '(' after #{kind} name.")

      parameters = []

      unless check?(:RIGHT_PAREN)
        parameters << consume(:IDENTIFIER, 'Expect parameter name')
        while match?(:COMMA)
          error(peek, "Can't have more than 255 parameters.") if parameters.length >= 255

          parameters << consume(:IDENTIFIER, 'Expect parameter name.')
        end
      end

      consume(:RIGHT_PAREN, "Expect ')' after parameters.")
      consume(:LEFT_BRACE, "Expect '{' before #{kind} body.")
      body = block

      Function.new(name, parameters, body)
    end

    #: () -> Array[Stmt]
    def block
      statements = []

      statements << declaration while !check?(:RIGHT_BRACE) && !at_end?

      consume(:RIGHT_BRACE, "Expect '}' after block.")
      statements
    end

    #: () -> Expr
    def assignment
      expr = _or

      if match?(:EQUAL)
        equals = previous
        value = assignment

        if expr.is_a?(Variable)
          name = expr.name
          return Assign.new(name, value)
        end

        error(equals, 'Invalid assignment target.')
      end

      expr
    end

    #: () -> Expr
    def _or
      expr = _and

      while match?(:OR)
        operator = previous
        right = _and
        expr = Logical.new(expr, operator, right)
      end

      expr
    end

    #: () -> Expr
    def _and
      expr = equality

      while match?(:AND)
        operator = previous
        right = equality
        expr = Logical.new(expr, operator, right)
      end

      expr
    end

    #: () -> Expr
    def equality
      expr = comparison

      while match?(:BANG_EQUAL, :EQUAL_EQUAL)
        operator = previous
        right = comparison
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    #: () -> Expr
    def comparison
      expr = term

      while match?(:GREATER, :GREATER_EQUAL, :LESS, :LESS_EQUAL)
        operator = previous
        right = term
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    #: () -> Expr
    def term
      expr = factor

      while match?(:MINUS, :PLUS)
        operator = previous
        right = factor
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    #: () -> Expr
    def factor
      expr = unary

      while match?(:SLASH, :STAR)
        operator = previous
        right = unary
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    #: () -> Expr
    def unary
      if match?(:BANG, :MINUS)
        operator = previous
        right = unary
        return Unary.new(operator, right)
      end

      call
    end

    #: () -> Expr
    def call
      expr = primary

      loop do
        break unless match?(:LEFT_PAREN)

        expr = finish_call(expr)
      end

      expr
    end

    #: (Expr) -> Expr
    def finish_call(callee)
      arguments = []

      unless check?(:RIGHT_PAREN)
        arguments << expression

        while match?(:COMMA)
          error(peek, "Can't have more than 255 arguments.") if arguments.size >= 255
          arguments << expression
        end
      end

      paren = consume(:RIGHT_PAREN, "Expect ')' after arguments.")

      Call.new(callee, paren, arguments)
    end

    #: () -> Expr
    def primary
      return Literal.new(false) if match?(:FALSE)
      return Literal.new(true) if match?(:TRUE)
      return Literal.new(nil) if match?(:NIL)
      return Literal.new(previous.literal) if match?(:NUMBER, :STRING)
      return Variable.new(previous) if match?(:IDENTIFIER)

      if match?(:LEFT_PAREN)
        expr = expression
        consume(:RIGHT_PAREN, "Expect ')' after expression.")
        return Grouping.new(expr)
      end

      raise error(peek, 'Expect expresison.')
    end

    #: (*Symbol) -> bool
    def match?(*types)
      if types.any? { |type| check?(type) }
        advance
        return true
      end

      false
    end

    #: (Symbol) -> bool
    def check?(type)
      return false if at_end?

      peek.type == type
    end

    #: () -> Token
    def advance
      @current += 1 unless at_end?
      previous
    end

    #: () -> bool
    def at_end?
      peek.type == :EOF
    end

    #: () -> Token
    def peek
      @tokens[@current] #: as !nil
    end

    #: () -> Token
    def previous
      @tokens[@current - 1] #: as !nil
    end

    #: (Symbol, String) -> Token
    def consume(type, message)
      return advance if check?(type)

      raise error(peek, message)
    end

    #: (Token, String) -> ParseError
    def error(token, message)
      Rlox.error(token, message)
      ParseError.new
    end

    #: () -> void
    def synchronize
      advance

      until at_end?
        return if previous.type == :SEMICOLON

        case peek.type
        when :CLASS, :FUN, :VAR, :FOR, :IF, :WHILE, :PRINT, :RETURN
          return
        end
        advance
      end
    end
  end
end
