require "./crysh/*"
require "colorize"

prompt = "❯ ".colorize(:blue)

def cd(dir)
  Dir.cd(dir)
end

def exit(code)
  if code.empty?
    Process.exit(0)
  else
    Process.exit(code.to_i)
  end
end

def exec(commands)
  Process.exec commands
end

BUILTINS = {
  "cd"   => ->cd (String),
  "exit" => ->exit (String),
  "exec" => ->exec (String),
}

loop do
  print prompt

  if (line = gets)
    line = line.strip
    args = line.split
    command = args.shift

    if BUILTINS.has_key? command.to_s
      BUILTINS[command.to_s].call(args.join)
    else
      pid = Process.fork {
        Process.exec line
      }

      pid.wait
    end
  end
end
