require "./crysh/lang/parser"
require "./crysh/lang/lexer"
require "./crysh/lang/interpreter"
require "./crysh/lang/ast"
require "../lib/cltk/src/cltk/parser/exceptions/not_in_language_exception"
require "colorize"

class Language
  def initialize
    @interpreter = Interpreter.new
  end

  def evaluate(input)
    puts "input: " + input.inspect
    puts "Begin lexing".colorize.green
    lex = Lexer.lex(input)
    pp lex.map { |t| [t.try(&.type), t.try(&.value)] }

    puts "Begin parsing".colorize.green
    ast = Parser.parse(lex)
    pp ast

    puts "Begin interpreting".colorize.green
    if ast.is_a?(CLTK::ASTNode)
      @interpreter.eval(ast)
    end
  rescue e : CLTK::Lexer::Exceptions::LexingError
    puts "Lexing error: Unspecified lexing error.".colorize.red
    pp e.backtrace
  rescue e : CLTK::Parser::Exceptions::NotInLanguage
    puts "Parsing error: Line was not in language.".colorize.red
    pp e.inspect
    pp e.backtrace
  rescue e : CLTK::Parser::Exceptions::BadToken
    puts "Parsing error: The parser encountered an unrecognized token.".colorize.red
    pp e.backtrace
  rescue e : Exception
    puts e.message, e.backtrace
    puts
  end
end

def main
  language = Language.new

  loop do
    print("Cryshlang > ".colorize.cyan)
    line = " "

    while line[-1..-1] != ";"
      line += " " unless line.empty?
      line += (gets || "")
    end

    if line == "quit;" || line == "exit;"
      break
    end

    language.evaluate(line)
  end
end

main # Primary execution point
# Language.new.evaluate("1-1; 5-2;")
# Language.new.evaluate("def foo() 1-1, 5-2 end;")
# Language.new.evaluate("def foo() 1-1; 2-2; end;")
