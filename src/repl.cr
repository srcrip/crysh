require "./cryshlang"

module REPL
  extend self

  def run
    lang = Cryshlang.new

    puts "\n\n" +
        "  Welcome to the CryshLang REPL, exit with: 'exit'  \n" +
        "----------------------------------------------------\n\n"

    while true
      begin
        # Read input.
        input = Readline.readline("»  ", true) || ""

        # Exit on exit.
        exit if input == "exit"

        # Evaluate.
        evaluated = lang.evaluate input

        # Output result of evaluation.
        puts evaluated
      end
    end
  end

end

REPL.run
