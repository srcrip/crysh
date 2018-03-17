BUILTINS = {
  "ls"     => ->ls(String),
  "cd"     => ->cd(String),
  "exit"   => ->exit_shell(String),
  "quit"   => ->exit_shell(String),
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
