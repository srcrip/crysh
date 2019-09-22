require "./crysh/*"
require "./crysh/builtins/*"
require "./cryshlang"
require "colorize"
require "fancyline"
include Options

# TODO support piping to positional arguments of commands like $(pwd) works in bash or (pwd) in fish. I think we should support both syntaxes for maximum compatability and ease of use at the same time.
# TODO right now theres an error when piping between builtins and non builtins.
# TODO add vim and emacs modes to fancyline.
# TODO indent to level of previous prompt when waiting for additional input

# some commands I've used to test process groups in crysh:
# sleep 5 | sleep 10 | sleep 15 | ps -o pid,pgid,ppid,args


# The startup method parses arguments the user passed in from command line.
startup

# waitpid uses two option flags, WUNTRACED and WNOHANG, value 2 and 1 respectively. If you want to use them both, combine them with a bitwise OR operator (|)
WUNTRACED = 2

lib LibC
  # sets current process to its own process group
  fun setpgrp : Int32
  # sets process specified by pid to process group specified by pgid
  fun setpgid(pid : PidT, pgid : PidT) : Int32
  # set the terminals foreground process group
  fun tcsetpgrp(fd : Int32, pgid : PidT) : Int32
  # get the terminals process group
  fun tcgetpgrp(fd : Int32) : Int32
  # make new session
  fun setsid : Int32
  fun tcgetsid(fd : Int32) : Int32
end

Signal::STOP.trap do |x|
  pp "SIGSTOP received\n"
  # if fg = Jobs.manager.fg
  #   fg.kill(Signal::STOP)
  # end
end

Signal::INT.trap do |x|
  pp "SIGINT received\n"
end

Signal::HUP.trap do |x|
  pp "SIGHUP received\n"
end

Dir.mkdir "#{ENV["HOME"]}/.config/" unless Dir.exists? "#{ENV["HOME"]}/.config/"
Dir.mkdir "#{ENV["HOME"]}/.config/crysh/" unless Dir.exists? "#{ENV["HOME"]}/.config/crysh/"

HISTFILE = "#{ENV["HOME"]}/.config/crysh/history.log"
CONFIG   = "#{ENV["HOME"]}/.config/crysh/config.yml"

module Crysh
  struct Prompt
    property normal, continued, string

    def initialize(@normal : Proc(String), @continued : String, @string : String)
    end

    def normal
      @normal.call
    end
  end

  class CLI
    property fancy : Fancyline

    def initialize(@prompt : Prompt)
      @fancy = get_fancy
    end

    def run
      # Initialize the interpreter.
      lang = Cryshlang.new

      # Grab our process group id
      initial_pgid = LibC.tcgetpgrp(STDOUT.fd)

      begin
        LibC.setsid
      rescue err : Errno
        puts "crysh: failure to become session leader. Is tty interactive?"
      end

      loop do
        input = collect_input

        next if input.nil? || input.empty?

        break if input == "exit" || input == "quit"

        # Expand environment variables, and other things that need expansion before processing.
        input = expand input

        evaluated = lang.evaluate input

        # The interpreter returns nil upon inputs that would return undefined.
        if evaluated == nil
          # If the interpreter can't figure things out, it might be a shell
          # command, so we pass it to this method.
          InputHandler.interpret input, initial_pgid
        else
          puts evaluated.to_s
        end
      end

      # save all the history from this session.
      save_history(@fancy)
    end

    # Collect a single line of input. A line can be continued by escaping the
    # newline with \.
    def collect_input
      input = @fancy.readline(@prompt.normal)

      # The following only trips upon input == EOF, Ie, the user hit ctrl-d.
      # Ctrl-c purposefully will not return nil.
      exit if input.nil?

      # TODO detect unclosed quotations
      while !input.nil? && input.ends_with? '\\'
        input = input.rchop '\\'
        input += " " + (@fancy.readline(@prompt.continued) || "")
      end
      input
    end
  end
end

prompt = Crysh::Prompt.new(->{ Functions.crysh_prompt }, "| ", "\" ")
Crysh::CLI.new(prompt).run
