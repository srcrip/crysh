# coding: utf-8
require "./crysh/*"
require "colorize"
require "fancyline"

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

    p input
    # p test = expand_vars input

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

    processes = [] of Process

    current_job = Jobs.manager.add(Job.new)

    commands.each_with_index do |command, index|
      args = command.to_s.split
      program = args.shift

      p "Program: " + program if DEBUG

      if builtin? (program.to_s)
        call_builtin(program.to_s, args.join)
      else
        if index + 1 < commands.size
          pipe = IO.pipe
          placeholder_out = pipe.last
        else
          placeholder_out = STDOUT
        end

        processes.push spawn_program(program, args, placeholder_out, placeholder_in, first_proc)

        pp first_proc
        # # if this command is first in the job, set a flag that will later determine the process group id of the job
        # if !first_proc
        #   first_proc = processes.last
        # end

        # put this process in the fg of the shell, unless passed '&'
        Jobs.manager.fg = current_job
        # Jobs.manager.fg = processes.last

        placeholder_out.close unless placeholder_out == STDOUT
        placeholder_in.close unless placeholder_in == STDIN
        placeholder_in = pipe.first unless pipe.empty?
      end
    end

    processes.each do |p|
      # ret = p.wait
      # pp ret

      LibC.waitpid(p.pid, out status_ptr, WUNTRACED)
      pp status_ptr
    end
  end
end
# rescue err : Fancyline::Interrupt
#   puts "Exited Crysh ok."
# end

# save all the history from this session.
save_history(fancy)

# sleep 5 | sleep 10 | sleep 15 | ps -o pid,pgid,ppid,args
