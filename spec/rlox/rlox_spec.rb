# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'rlox'

RSpec.describe Rlox do
  define_method(:run_lox) do |source|
    output = StringIO.new
    $stdout = output
    begin
      described_class.send(:run, source)
    ensure
      $stdout = STDOUT
    end
    output.string
  end

  it 'evaluates arithmetic expressions' do
    expect(run_lox('print 1 + 2 * 3 - 4 / 2;')).to eq("5.0\n")
  end

  it 'handles variable declarations and assignments' do
    expect(run_lox('var a = 10; print a; a = a + 5; print a;')).to eq("10.0\n15.0\n")
  end

  it 'evaluates if/else statements' do
    source = <<~LOX
      var x = 3;
      if (x > 2) {
        print "big";
      } else {
        print "small";
      }
    LOX
    expect(run_lox(source)).to eq("big\n")
  end

  it 'evaluates while loops' do
    source = <<~LOX
      var i = 0;
      while (i < 3) {
        print i;
        i = i + 1;
      }
    LOX
    expect(run_lox(source)).to eq("0.0\n1.0\n2.0\n")
  end

  it 'evaluates for loops' do
    source = <<~LOX
      for (var i = 0; i < 3; i = i + 1) {
        print i;
      }
    LOX
    expect(run_lox(source)).to eq("0.0\n1.0\n2.0\n")
  end

  it 'handles logical operators' do
    expect(run_lox('print true or false;')).to eq("true\n")
    expect(run_lox('print false and true;')).to eq("false\n")
  end

  it 'handles string concatenation' do
    expect(run_lox('print "foo" + "bar";')).to eq("foobar\n")
  end

  it 'prints nil for uninitialized variables' do
    expect(run_lox('var x; print x;')).to eq("\n")
  end

  it 'reports runtime errors for undefined variables' do
    expect do
      run_lox('print y;')
    end.to output(/Undefined variable/).to_stderr
  end

  it 'reports errors for type mismatches' do
    expect do
      run_lox('print 1 + "a";')
    end.to output(/Operands must be two numbers or two strings/).to_stderr
  end
end
