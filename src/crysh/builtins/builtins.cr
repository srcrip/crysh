def ls(string)
  Process.run("ls", ["-l", "--color=auto"], output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
end

def la(string)
  Process.run("ls", ["-lah", "--color=auto"], output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
end

def cd(dir)
  # beautiful code below
  dir = "/" if dir == ""
  dir = "../../" if dir == "..."
  dir = "../../../" if dir == "...."
  dir = "../../../../" if dir == "....."
  dir = File.expand_path(dir)
  Dir.cd(dir)
rescue err : Errno
  puts "crysh: unknown directory."
end

# Don't rename this to `exit` as that's in the global namespace.
def exit_shell(code)
  exit
end

def grep(args)
  Process.exec "grep --color=auto " + args
end

def execute(commands)
  Process.exec commands
end

def export(args)
  key, value = args.split('=')
  ENV[key] = value
end

def shell_alias(input)
  name, command = input.split('=')
  puts "Made alias " + name + " = " + command if debug?
end

def help(args)
  puts "\n-- Welcome to crysh shell --\n\n"
  "Help: see https://github.com/Sevensidedmarble/crysh for more information."
end
