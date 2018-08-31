require "./types"
require "cltk/scanner"

# The lexer (or scanner) that turns plaintext input into tokens for the parser.
class Lexer < CLTK::Scanner
  extend CLTK::Scanner::LexerCompatibility

  # Skip whitespace.
  rule(" ")

  # Keywords
  rule("def") { {:DEF} }
  rule("end") { {:END} }
  rule("extern") { {:EXTERN} }
  rule("if") { {:IF} }
  rule("then") { {:THEN} }
  rule("else") { {:ELSE} }
  rule("for") { {:FOR} }
  rule("in") { {:IN} }

  # Operators and delimiters.
  rule("(") { {:LPAREN} }
  rule(")") { {:RPAREN} }
  rule(";") { {:SEMI} }
  rule(",") { {:COMMA} }
  rule("=") { {:ASSIGN} }
  rule("+") { {:PLUS} }
  rule("-") { {:SUB} }
  rule("*") { {:MUL} }
  rule("/") { {:DIV} }
  rule("<") { {:LT} }
  rule(">") { {:GT} }
  rule("!") { {:BANG} }
  rule("|") { {:PIPE} }
  rule("&") { {:AMP} }
  rule("==") { {:EQL} }
  rule(":") { {:SEQ} }

  # Identifier rule.
  rule(/[A-Za-z][A-Za-z0-9]*/) { |t| {:IDENT, t} }

  # Numeric rules.
  rule(/\d+/) { |t| {:NUMBER, t.to_f} }
  rule(/\.\d+/) { |t| {:NUMBER, t.to_f} }
  rule(/\d+\.\d+/) { |t| {:NUMBER, t.to_f} }

  # Comment rules.
  rule("#") { |m| push_state :comment }
  rule("\n", :comment) { |m| pop_state }
  rule(/./, :comment)
end
