require "readline"
require "./cryshlang/lexer"
require "./cryshlang/ast"
require "./cryshlang/scope"
require "./cryshlang/parser"
require "./cryshlang/exceptions"
require "./cltk/macros"
require "./cltk/parser/type"
require "./cltk/parser/parser_concern"

DEBUG = false

class Cryshlang
  def initialize
    @lexer  = EXP_LANG::Lexer
    @parser = EXP_LANG::Parser
    @scope  = EXP_LANG::Scope(Expression).new
  end

  def evaluate(input = "")
    if input == ""
      puts "No input!"
    else
      interprate(parse(lex(input)))
    end
  rescue e: CLTK::Lexer::Exceptions::LexingError
    show_lexing_error(e, input)
  rescue e: CLTK::NotInLanguage
    show_syntax_error(e, input)
  rescue e
    puts e
  end

  # Lex input.
  def lex(input)
    @lexer.lex(input).tap do |tokens|
      pp tokens if DEBUG
    end
  end

  # Parse lexed tokens.
  def parse(tokens)
    @parser.parse(tokens, {accept: :first}).as(CLTK::ASTNode).tap do |tree|
      pp tree if DEBUG
    end
  end

  # Evaluate the AST tree with a given scope.
  # (scope my be altered by the expression)
  def interprate(tree)
    tree.eval_scope(@scope)
  end

  def show_lexing_error(e, input)
    puts "Lexing error at:\n\n"
    puts "    " + input.split("\n")[e.line_number-1]
    puts "    " + e.line_offset.times().map { "-" }.join + "^"
    puts e
  end

  def show_syntax_error(e, input)
    pos = e.current.position
    if pos
      puts "Syntax error at:"
      puts "    " + input.split("\n")[pos.line_number-1]
      puts "    " + pos.line_offset.times().map { "-" }.join + "^"
    else
      puts "invalid input: #{input}"
    end
  end
end

# main
# Language.new.evaluate("1-1; 5-2;")
# Language.new.evaluate("def foo() 1-1, 5-2 end;")
# Language.new.evaluate("def foo() 1-1; 2-2; end;")
