# coding: utf-8
require "./crysh/*"
require "colorize"
require "fancyline"

# HISTFILE = "#{Dir.current}/history.log"

Dir.mkdir "#{ENV["HOME"]}/.config/" unless Dir.exists? "#{ENV["HOME"]}/.config/"
Dir.mkdir "#{ENV["HOME"]}/.config/crysh/" unless Dir.exists? "#{ENV["HOME"]}/.config/crysh/"

HISTFILE = "#{ENV["HOME"]}/.config/crysh/history.log"
CONFIG   = "#{ENV["HOME"]}/.config/crysh/config.yml"

DEBUG = false

fancy = get_fancy

# prompt = "❯ ".colorize(:blue)
prompt = "❯ "

# this is a flag to check for additional input after the \ char
more_input = false
last_input = ""

def crysh_prompt
  puts "❯ "
end

# HELPERS
def expand_vars(input)
  ENV[input.lchop('$')] if input =~ /(\\$)(?:[a-z][a-z]+)/
  input.gsub(/(\\$)(?:[a-z][a-z]+)/, "\1")
end

def spawn_program(program, arguments, placeholder_out, placeholder_in)
  Process.fork {
    unless placeholder_out == STDOUT
      STDOUT.reopen(placeholder_out)
      placeholder_out.close
    end

    unless placeholder_in == STDIN
      STDIN.reopen(placeholder_in)
      placeholder_in.close
    end
    begin
      Process.exec program, arguments
    rescue err : Errno
      puts "crysh: unknown command."
    end
  }
end

def split_on_pipes(line)
  # line.match(/([^"'|]+)|["']([^"']+)["']/).flatten.compact
  # line.scan(/([^"'|]+)|["']([^"']+)["']/)
  line.split('|')
end

def builtin?(program)
  BUILTINS.has_key?(program)
end

def call_builtin(program, arguments)
  BUILTINS[program].call(arguments)
end

def get_command(ctx)
  line = ctx.editor.line
  cursor = ctx.editor.cursor.clamp(0, line.size - 1)
  pipe = line.rindex('|', cursor)
  line = line[(pipe + 1)..-1] if pipe

  line.split.first?
end

if File.exists? HISTFILE # Does it exist?
  puts "Reading history from #{HISTFILE}" if DEBUG
  File.open(HISTFILE, "r") do |io| # Open a handle
    fancy.history.load io          # And load it
  end
end

begin # Get rid of stacktrace on ^C
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

          processes.push spawn_program(program, args, placeholder_out, placeholder_in)

          # p pipe.empty?

          placeholder_out.close unless placeholder_out == STDOUT
          placeholder_in.close unless placeholder_in == STDIN
          placeholder_in = pipe.first unless pipe.empty?
        end
      end

      processes.each(&.wait)
    end
  end
rescue err : Fancyline::Interrupt
  puts "Exited Crysh ok."
end

File.open(HISTFILE, "w") do |io| # So open it writable
  fancy.history.save io          # And save.  That's it.
end
