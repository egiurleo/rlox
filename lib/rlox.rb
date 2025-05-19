# typed: strict
# frozen_string_literal: true

require 'rlox/scanner'
require 'rlox/parser'
require 'rlox/interpreter'
require 'rlox/ast_printer'
require 'debug'

class Rlox
  @interpreter = Interpreter.new #: Interpreter
  @had_error = false #: bool
  @had_runtime_error = false #:bool

  class << self
    #: (String) -> void
    def main(*args)
      if args.length > 1
        puts 'Usage: ...'
        exit(1)
      elsif args.length == 1
        arg = args.first
        return if arg.nil?

        run_file(arg)
      else
        run_prompt
      end
    end

    #: (String) -> void
    def run_file(path)
      source = File.read(path)
      run(source)

      exit(65) if @had_error
      exit(70) if @had_runtime_error
    end

    #: () -> void
    def run_prompt
      loop do
        print '> '
        line = gets
        break if line.nil?

        run(line)
        @had_error = false
      end
    end

    #: (String) -> void
    def run(source)
      scanner = Scanner.new(source)
      tokens = scanner.scan_tokens

      parser = Parser.new(tokens)
      expression = parser.parse

      return if @had_error

      return if expression.nil?

      @interpreter.interpret(expression)
    end

    #: (Integer, String) -> void
    def error(line, message)
      report(line, '', message)
    end

    #: (Token, String) -> void
    def error_token(token, message)
      if token.type == :EOF
        report(token.line, ' at end', message)
      else
        report(token.line, "at '#{token.lexeme}'", message)
      end
    end

    #: (RuntimeError) -> void
    def runtime_error(error)
      warn <<~ERROR
        #{error.message}
        [line #{error.token.line}]
      ERROR

      @had_runtime_error = true
    end

    private

    #: (Integer, String, String) -> void
    def report(line, where, message)
      warn("[line #{line}] Error#{where}: #{message}")
      @had_error = true
    end
  end
end
