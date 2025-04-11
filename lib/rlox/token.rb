# typed: strict

class Rlox
  class Token
    TYPES = %i[
      LEFT_PAREN RIGHT_PAREN LEFT_BRACE RIGHT_BRACE
      COMMA DOT MINUS PLUS SEMICOLON SLASH STAR

      BANG BANG_EQUAL
      EQUAL EQUAL_EQUAL
      GREATER GREATER_EQUAL
      LESS LESS_EQUAL

      IDENTIFIER STRING NUMBER

      AND CLASS ELSE FALSE FUN FOR IF NIL OR
      PRINT RETURN SUPER THIS TRUE VAR WHILE

      EOF
    ].freeze

    class << self
      #: (Symbol) -> void
      def verify_type!(type)
        raise ArgumentError unless TYPES.include?(type)
      end
    end

    #: Symbol
    attr_reader :type

    #: String
    attr_reader :lexeme

    #: untyped
    attr_reader :literal

    #: (Symbol, String, untyped, Integer) -> void
    def initialize(type, lexeme, literal, line)
      Token.verify_type!(type)

      @type = type
      @lexeme = lexeme
      @literal = literal
      @line = line
    end

    #: () -> void
    def to_s
      "<Rlox::Token:#{object_id} @lexeme=#{@lexeme} @literal=#{@literal} @type=#{@type}"
    end
  end
end
