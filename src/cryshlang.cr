require "./crysh/lang/parser"
require "./crysh/lang/lexer"
require "./crysh/lang/interpreter"
require "./crysh/lang/ast"
require "../lib/cltk/src/cltk/parser/exceptions/not_in_language_exception"

class Language
  def initialize
    @interpreter = Interpreter.new
  end

  def evaluate(input)
    puts "Begin lexing"
    lex = Lexer.lex(input)
    pp lex

    puts "Begin parsing"
    ast = Parser.parse(lex)
    pp ast

    puts "Begin interpreting"
    if ast.is_a?(CLTK::ASTNode)
      @interpreter.eval(ast)
    end
  rescue e : CLTK::Lexer::Exceptions::LexingError
    puts "Lexing error: Unspecified lexing error."
    pp e.backtrace
  rescue e : CLTK::Parser::Exceptions::NotInLanguage
    puts "Parsing error: Line was not in language."
    pp e.backtrace
  rescue e : CLTK::Parser::Exceptions::BadToken
    puts "Parsing error: The parser encountered an unrecognized token."
    puts e.to_s
    pp e.backtrace
  rescue e : Exception
    puts e.message, e.backtrace
    puts
  end
end

def main
  language = Language.new

  loop do
    print("Cryshlang > ")
    line = " "

    while line[-1..-1] != ";"
      line += " " unless line.empty?
      line += (gets || "").chomp
    end

    if line == "quit;" || line == "exit;"
      break
    end

    language.evaluate(line)
  end
end

# begin main loop
main
