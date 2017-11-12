# coding: utf-8
require "./crysh/*"
require "option_parser"
require "colorize"
require "fancyline"

# TODO right now theres an error when piping between builtins and non builtins.
# TODO add vim and emacs modes to fancyline.
# TODO the whole more_input and last_input thing is ugly as sin and should probably be just some array called lines.
# TODO fix stacktrace when using exit command.
# TODO indent to level of previous prompt when waiting for additional input

# By default, crysh starts in interactive mode. Pass -c to force command mode.
interactive = true
# By default, crysh starts with debug off. Pass -d to force debug mode on.
debug = false
# Version information
VERSION = "crysh: version 0.1.0
crystal version: #{Crystal::VERSION}
♥ thank you for using crysh ♥
"

# Parse options and flags on startup.
OptionParser.parse! do |parser|
  parser.banner = "crysh: the crystal shell"
  parser.on("-c", "--command=COMMANDS", "Evaluate the specified commands and exit instead of entering interactive mode.") do |cmd|
    interactive = false
    puts cmd
    # TODO implement command mode
  end
  parser.on("-d", "--debug", "Turns debug on mode for developers.") do
    debug = true
 end
  parser.on("-v", "--version", "Display version information and exit.") do
    puts VERSION
    exit 0
  end
  parser.on("-h", "--help", "Display this help message and exit.") do
    puts parser
    exit 0
  end
end

# Exit if the user passed -c
exit 0 unless interactive

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

# Flag to print some helper notices.
DEBUG = false

# some commands I've used to test process groups in crysh:
# sleep 5 | sleep 10 | sleep 15 | ps -o pid,pgid,ppid,args

module Crysh
  struct Prompt
    property normal, continued, string

    def initialize(@normal : String, @continued : String, @string : String)
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
        next if input.nil?
        break if input == "exit" # TODO make this graceful exit not a hack
        commands = split_on_pipes(input)

        # Add the gathered commands into a job
        job = Jobs.manager.add(Job.new)
        commands.each_with_index do |command, index|
          job.add_command(command, index)
        end

        # Wait for the whole job to finish before completing the loop
        job.processes.each do |proc|
          LibC.waitpid(proc.pid, out status_ptr, WUNTRACED)
          pp status_ptr if DEBUG
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

# prompt = "❯ ".colorize(:blue)
# prompt = "❯ "
prompt = Crysh::Prompt.new("❯ ", "| ", "\" ")
Crysh::CLI.new(prompt).run
