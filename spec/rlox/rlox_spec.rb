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

  it 'executes a user-defined function' do
    result = run_lox(<<~LOX)
      fun sayHi(first, last) {
        print "Hi, " + first + " " + last + "!";
      }

      sayHi("Dear", "Reader");
    LOX

    expect(result).to eq("Hi, Dear Reader!\n")
  end

  it 'executes a simple function' do
    result = run_lox(<<~LOX)
      fun one() {
        return 1;
      }

      print one();
    LOX

    expect(result).to eq("1.0\n")
  end

  it 'executes a function with a return value' do
    result = run_lox(<<~LOX)
      fun fib(n) {
        if (n <= 1) return n;
        return fib(n - 2) + fib(n - 1);
      }

      for (var i = 0; i < 5; i = i + 1) {
        print fib(i);
      }
    LOX

    expect(result).to eq("0.0\n1.0\n1.0\n2.0\n3.0\n")
  end

  it 'executes closures' do
    result = run_lox(<<~LOX)
      fun makeCounter() {
        var i = 0;
        fun count() {
          i = i + 1;
          print i;
        }

        return count;
      }

      var counter = makeCounter();
      counter();
      counter();
    LOX

    expect(result).to eq("1.0\n2.0\n")
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

  it 'evaluates closures' do
    result = run_lox(<<~LOX)
      var a = "global";
      {
        fun showA() {
          print a;
        }

        showA();
        var a = "block";
        showA();
      }
    LOX

    expect(result).to eq("global\nglobal\n")
  end

  it 'calls instance methods' do
    result = run_lox(<<~LOX)
      class Bacon {
        init() {}

        eat() {
          print "Crunch crunch crunch!";
        }
      }

      Bacon().eat();
    LOX

    expect(result).to eq("Crunch crunch crunch!\n")
  end

  it 'allows instances to store state' do
    result = run_lox(<<~LOX)
      class Cake {
        init() { }
        taste() {
          var adjective = "delicious";
          print "The " + this.flavor + " cake is " + adjective + "!";
        }
      }

      var cake = Cake();
      cake.flavor = "German chocolate";
      cake.taste();
    LOX

    expect(result).to eq("The German chocolate cake is delicious!\n")
  end
end
