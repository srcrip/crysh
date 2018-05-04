require "./crysh/*"
require "./crysh/builtins/*"
require "colorize"
require "fancyline"
include Options

# TODO support piping to positional arguments of commands like $(pwd) works in bash or (pwd) in fish. I think we should support both syntaxes for maximum compatability and ease of use at the same time.
# TODO right now theres an error when piping between builtins and non builtins.
# TODO add vim and emacs modes to fancyline.
# TODO indent to level of previous prompt when waiting for additional input

# The startup method parses arguments the user passed in from command line.
startup

# waitpid uses two option flags, WUNTRACED and WNOHANG, value 2 and 1 respectively. If you want to use them both, combine them with a bitwise OR operator (|)
WUNTRACED = 2

lib LibC
  # sets current process to its own process group
  fun setpgrp : Int32
  # sets process specified by pid to process group specified by pgid
  fun setpgid(pid : PidT, pgid : PidT) : Int32
end

# Signal::STOP.trap do |x|
#   puts "Got SIGSTOP"
#   # if fg = Jobs.manager.fg
#   #   fg.kill(Signal::STOP)
#   # end
# end

# Signal::INT.trap do |x|
#   puts "Got SIGINT"
# end

Dir.mkdir "#{ENV["HOME"]}/.config/" unless Dir.exists? "#{ENV["HOME"]}/.config/"
Dir.mkdir "#{ENV["HOME"]}/.config/crysh/" unless Dir.exists? "#{ENV["HOME"]}/.config/crysh/"

HISTFILE = "#{ENV["HOME"]}/.config/crysh/history.log"
CONFIG   = "#{ENV["HOME"]}/.config/crysh/config.yml"

# some commands I've used to test process groups in crysh:
# sleep 5 | sleep 10 | sleep 15 | ps -o pid,pgid,ppid,args

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
      loop do
        # Collect the input string and split it into a list of separate commands
        # to be piped into each other.
        input = collect_input
        next if input.nil? || input.empty?
        break if input == "exit" # TODO make this graceful exit not a hack
        # Expand things like $vars or the $() syntax before proceeding
        input = expand input
        commands = split_on_pipes(input)

        # Add the gathered commands into a job
        job = Jobs.manager.add(Job.new)
        commands.each_with_index do |command, index|
          job.add_command(command, index)
        end

        # Wait for the whole job to finish before completing the loop
        job.processes.each do |proc|
          LibC.waitpid(proc.pid, out status_ptr, WUNTRACED)
          pp status_ptr if debug?
        end
      end

      # save all the history from this session.
      save_history(@fancy)
    end

    # Collect a single line of input. A line can be continued by escaping the
    # newline with \.
    def collect_input
      input = @fancy.readline(@prompt.normal)
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
