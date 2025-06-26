# typed: false
# frozen_string_literal: true

require 'rlox'

describe Rlox::Scanner do
  describe '#scan_tokens' do
    it 'returns EOF token given an empty source' do
      scanner = described_class.new('')
      tokens = scanner.scan_tokens

      expect(tokens.length).to eq(1)
      expect_eof(tokens.first)
    end

    it 'returns TRUE token given true boolean' do
      scanner = described_class.new('true')
      tokens = scanner.scan_tokens

      expect(tokens.length).to eq(2)
      expect_token(tokens.first, :TRUE, 'true')
    end

    it 'returns FALSE token given false boolean' do
      scanner = described_class.new('false')
      tokens = scanner.scan_tokens

      expect(tokens.length).to eq(2)
      expect_token(tokens.first, :FALSE, 'false')
    end

    it 'returns NUMBER token given integer' do
      scanner = described_class.new('123')
      tokens = scanner.scan_tokens

      expect(tokens.length).to eq(2)
      expect_token(tokens.first, :NUMBER, '123', 123.0)
    end

    it 'returns NUMBER token given float' do
      scanner = described_class.new('12.3')
      tokens = scanner.scan_tokens

      expect(tokens.length).to eq(2)
      expect_token(tokens.first, :NUMBER, '12.3', 12.3)
    end

    it 'returns STRING token given empty string' do
      scanner = described_class.new('""')
      tokens = scanner.scan_tokens

      expect(tokens.length).to eq(2)
      expect_token(tokens.first, :STRING, '""')
    end

    it 'returns STRING token given string' do
      scanner = described_class.new('"I am a string"')
      tokens = scanner.scan_tokens

      expect(tokens.length).to eq(2)
      expect_token(tokens.first, :STRING, '"I am a string"', 'I am a string')
    end

    it 'returns EXPRESSION token given an arithmetic expression' do
      scanner = described_class.new('100 + 5')
      tokens = scanner.scan_tokens

      expect(tokens.length).to eq(4)
      expect_token(tokens.first, :NUMBER, '100', 100.0)
      expect_token(tokens[1], :PLUS, '+')
      expect_token(tokens[2], :NUMBER, '5', 5.0)
    end
  end

  private

  define_method(:expect_token) do |token, type, lexeme = nil, literal = nil|
    expect(token).to be_a(Rlox::Token)
    expect(token.type).to eq(type)
    expect(token.lexeme).to eq(lexeme) if lexeme
    expect(token.literal).to eq(literal) if literal
  end

  define_method(:expect_eof) do |token|
    expect_token(token, :EOF)
  end
end
