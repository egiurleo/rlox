# typed: strict
# frozen_string_literal: true

require 'rlox/token'
require 'rlox/expr'

class Rlox
  class Parser
    class ParseError < StandardError; end

    #: (Array[Token]) -> void
    def initialize(tokens)
      @tokens = tokens
      @current = 0 #: Integer
    end

    #: () -> Expr?
    def parse
      expression
    rescue ParseError
      nil
    end

    private

    #: () -> Expr
    def expression
      equality
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

      primary
    end

    #: () -> Expr
    def primary
      return Literal.new(false) if match?(:FALSE)
      return Literal.new(true) if match?(:TRUE)
      return Literal.new(nil) if match?(:NIL)
      return Literal.new(previous.literal) if match?(:NUMBER, :STRING)

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
      Rlox.error_token(token, message)
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
