require "./crysh/*"
require "colorize"

DEBUG = true
prompt = "❯ ".colorize(:blue)

# BUILTINS
def cd(dir)
  Dir.cd(dir)
end

def exit(code)
  if code.empty?
    Process.exit
  else
    Process.exit(code.to_i)
  end
end

def exec(commands)
  Process.exec commands
end

def export(args)
  key, value = args.split('=')
  ENV[key] = value
end

# HELPERS
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

    Process.exec program, arguments
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

BUILTINS = {
  "cd"     => ->cd (String),
  "exit"   => ->exit (String),
  "exec"   => ->exec (String),
  "export" => ->export (String),
}

loop do
  print prompt

  if (line = gets)
    # strip the newline character from input
    line = line.strip

    commands = split_on_pipes(line)
    pp commands

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

    # if BUILTINS.has_key? command.to_s
    #   BUILTINS[command.to_s].call(args.join)
    # else
    #   pid = Process.fork {
    #     Process.exec line
    #   }

    #   pid.wait
    # end
  end
end
