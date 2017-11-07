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

BUILTINS = {
  "cd"     => ->cd (String),
  "exit"   => ->exit (String),
  "exec"   => ->exec (String),
  "export" => ->export (String),
}
