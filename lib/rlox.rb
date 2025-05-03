# typed: strict
# frozen_string_literal: true

require 'rlox/scanner'
require 'debug'

class Rlox
  @had_error = false #: bool

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

      exit(1) if @had_error
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

      tokens.each do |token|
        puts token
      end
    end

    #: (Integer, String) -> void
    def error(line, message)
      report(line, '', message)
    end

    private

    #: (Integer, String, String) -> void
    def report(line, where, message)
      warn("[line #{line}] Error#{where}: #{message}")
      @had_error = true
    end
  end
end
