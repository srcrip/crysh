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

def grep(args)
  Process.exec "grep --color=auto " + args
end

def shell_alias(input)
  name, command = input.split('=')
  puts "Made alias " + name + " = " + command if DEBUG
end

BUILTINS = {
  "cd"     => ->cd (String),
  "exit"   => ->exit (String),
  "exec"   => ->exec (String),
  "export" => ->export (String),
  "grep"   => ->grep (String),
  "alias"  => ->shell_alias (String),
}

def builtin?(program)
  BUILTINS.has_key?(program)
end

def call_builtin(program, arguments)
  BUILTINS[program].call(arguments)
end
