# typed: strict
# frozen_string_literal: true

require 'rlox/token'

class Rlox
  class Scanner
    KEYWORDS = {
      'and' => :AND,
      'class' => :CLASS,
      'else' => :ELSE,
      'false' => :FALSE,
      'for' => :FOR,
      'fun' => :FUN,
      'if' => :IF,
      'nil' => :NIL,
      'or' => :OR,
      'print' => :PRINT,
      'return' => :RETURN,
      'super' => :SUPER,
      'this' => :THIS,
      'true' => :TRUE,
      'var' => :VAR,
      'while' => :WHILE
    }.freeze #: Hash[String, Symbol]

    #: (String) -> void
    def initialize(source)
      @source = source
      @tokens = []  #: Array[Token]
      @start = 0    #: Integer
      @current = 0  #: Integer
      @line = 1     #: Integer
    end

    #: () -> Array[Token]
    def scan_tokens
      until at_end?
        @start = @current
        scan_token
      end

      @tokens << Token.new(:EOF, '', nil, @line)
    end

    private

    #: () -> void
    def scan_token
      char = advance
      case char
      when '(' then add_token(:LEFT_PAREN)
      when ')' then add_token(:RIGHT_PAREN)
      when '{' then add_token(:LEFT_BRACE)
      when '}' then add_token(:RIGHT_BRACE)
      when ',' then add_token(:COMMA)
      when '.' then add_token(:DOT)
      when '-' then add_token(:MINUS)
      when '+' then add_token(:PLUS)
      when ';' then add_token(:SEMICOLON)
      when '*' then add_token(:STAR)
      when '!'
        add_token(match?('=') ? :BANG_EQUAL : :BANG)
      when '='
        add_token(match?('=') ? :EQUAL_EQUAL : :EQUAL)
      when '<'
        add_token(match?('=') ? :LESS_EQUAL : :LESS)
      when '>'
        add_token(match?('=') ? :GREATER_EQUAL : :GREATER)
      when '/'
        if match?('/')
          advance while peek != '\n' && !at_end?
        else
          add_token(:SLASH)
        end
      when ' ', "\r", "\t"
        # ignore whitespace
      when "\n"
        @line += 1
      when '"'
        string
      else
        if digit?(char)
          number
        elsif alpha?(char)
          identifier
        else
          Rlox.error(@line, 'Unexpected character.')
        end
      end
    end

    #: () -> bool
    def at_end?
      @current >= @source.length
    end

    #: () -> String
    def advance
      @current += 1
      @source[@current - 1] #: as !nil
    end

    #: (Symbol, untyped) -> void
    def add_token(type, literal = nil)
      Token.verify_type!(type)

      text = @source[@start...@current] #: as !nil
      @tokens << Token.new(type, text, literal, @line)
    end

    #: (String) -> bool
    def match?(expected)
      return false if at_end?
      return false if @source[@current] != expected

      @current += 1
      true
    end

    #: () -> String
    def peek
      return '\0' if at_end?

      @source[@current] #: as !nil
    end

    #: () -> String
    def peek_next
      return '\0' if @current + 1 >= @source.length

      @source[@current + 1] #: as !nil
    end

    #: () -> void
    def string
      while peek != '"' && !at_end?
        @line += 1 if peek == '\n'
        advance
      end

      if at_end?
        Rlox.error(@line, 'Unterminated string.')
        return
      end

      advance

      value = @source[@start + 1...@current - 1]
      add_token(:STRING, value)
    end

    #: (String) -> bool
    def digit?(c)
      c.between?('0', '9')
    end

    #: () -> void
    def number
      advance while digit?(peek)

      if peek == '.' && digit?(peek_next)
        advance
        advance while digit?(peek)
      end

      add_token(:NUMBER, @source[@start...@current].to_f)
    end

    #: () -> void
    def identifier
      advance while alphanumeric?(peek)

      text = @source[@start...@current] #: as !nil
      type = KEYWORDS[text] || :IDENTIFIER

      add_token(type)
    end

    #: (String) -> bool
    def alpha?(c)
      c.between?('a', 'z') || c.between?('A', 'Z') || c == '_'
    end

    #: (String) -> bool
    def alphanumeric?(c)
      alpha?(c) || digit?(c)
    end
  end
end
