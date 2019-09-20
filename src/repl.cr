require "./cryshlang"

module REPL
  extend self

  def run
    lang = Cryshlang.new

    puts "\n\n" +
        "  Welcome to the CryshLang REPL, exit with: 'exit'  \n" +
        "----------------------------------------------------\n\n"

    loop do
      begin
        evaluate(lang, Readline.readline("»  ", true) || "")
      end
    end
  end

  def evaluate(lang = Cryshlang.new, input = "")
    # Exit on exit.
    exit if input == "exit"
    # Evaluate.
    evaluated = lang.evaluate input
    # Output result of evaluation.
    puts evaluated.to_s
  end
end

# The following can be done to evaluate a single expression:
# REPL.evaluate(Cryshlang.new, "1+1")

# Otherwise:
REPL.run
