require "./crysh/*"

prompt = "❯ "

def cd(dir)
  Dir.cd(dir)
end

def exit(code)
  if code
    exit(code.to_i)
  else
    exit(0)
  end
end

BUILTINS = {
  "cd"   => ->cd (String),
  "exit" => ->exit (String),
}

loop do
  print prompt

  if (line = gets)
    line = line.strip
    args = line.split
    command = args.shift

    if BUILTINS.has_key? command.to_s
      BUILTINS[command.to_s].call(args.to_s)
    else
      pid = Process.fork {
        Process.exec line
      }

      pid.wait
    end
  end
end
