# TODO many builtins need to be added. Look at what bash/zsh/fish implement and go from there.

def ls(string)
  Process.run("ls", ["-l", "--color=auto"], output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
end

def cd(dir)
  Dir.cd(dir)
end

# don't rename this to `exit` as that's in the global namespace.
def exit_shell(code)
  if code.empty?
    Process.exit
  else
    Process.exit(code.to_i)
  end
end

def execute(commands)
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
  puts "Made alias " + name + " = " + command if debug?
end

BUILTINS = {
  "ls"     => ->ls(String),
  "cd"     => ->cd(String),
  "exit"   => ->exit_shell(String),
  "exec"   => ->execute(String),
  "export" => ->export(String),
  "grep"   => ->grep(String),
  "alias"  => ->shell_alias(String),
}

def builtin?(program)
  BUILTINS.has_key?(program)
end

def call_builtin(program, arguments)
  BUILTINS[program].call(arguments)
end
