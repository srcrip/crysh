# coding: utf-8
require "./crysh/*"
require "colorize"
require "fancyline"

# TODO right now theres an error when piping between builtins and non builtins.
# TODO add vim and emacs modes to fancyline.
# TODO the whole more_input and last_input thing is ugly as sin and should probably be just some array called lines.
# TODO fix stacktrace when using exit command.

# waitpid uses two option flags, WUNTRACED and WNOHANG, value 2 and 1 respectively. If you want to use them both, combine them with a bitwise OR operator (|)
WUNTRACED = 2

lib LibC
  # sets current process to its own process group
  fun setpgrp : Int32
  # sets process specified by pid to process group specified by pgid
  fun setpgid(pid : PidT, pgid : PidT) : Int32
end

first_proc = nil

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

# Fancyline is a really nice crystal library for editing and dealing with text on the command line.
fancy = get_fancy

# prompt = "❯ ".colorize(:blue)
prompt = "❯ "

# this is a flag to check for additional input after the \ char
more_input = false
last_input = ""

# open the history file (or make it if it exists) and load it for use
load_history(fancy)

# begin # Get rid of stacktrace on ^C
loop do
  if more_input
    input = fancy.readline(" ")
  else
    input = fancy.readline(prompt.to_s)
  end

  more_input = false

  if input
    # strip the newline character from input
    input = last_input + input.strip

    # If the last line of the input is \, stop parsing and wait for additional input
    if input.ends_with? '\\'
      input = input.rchop '\\'
      more_input = true
      last_input = input
      next
    end

    commands = split_on_pipes(input)

    p "Commands: " if DEBUG
    pp commands if DEBUG

    placeholder_in = STDIN
    placeholder_out = STDOUT
    pipe = [] of IO::FileDescriptor

    # TODO instead of making the job and then iterating commands and adding to job one at a time, just pass the commands array to the initializer of jobs.
    current_job = Jobs.manager.add(Job.new)

    # TODO add bg and fg support to jobs, then make appending a command with '&' spawn a process in the bg.
    commands.each_with_index do |command, index|
      current_job.add_command(command, index)
    end

    current_job.processes.each do |p|
      # I changed this from wait to waitpid, but I'm still experimenting.
      # ret = p.wait
      # pp ret
      LibC.waitpid(p.pid, out status_ptr, WUNTRACED)
      pp status_ptr if DEBUG
    end
  end
end
# rescue err : Fancyline::Interrupt
#   puts "Exited Crysh ok."
# end

# save all the history from this session.
save_history(fancy)

# some commands I've used to test process groups in crysh:
# sleep 5 | sleep 10 | sleep 15 | ps -o pid,pgid,ppid,args
