module Builtin
  extend self

  LIST = {
    "ls"     => ->ls(String),
    "la"     => ->la(String),
    "cd"     => ->cd(String),
    "exit"   => ->exit_shell(String),
    "quit"   => ->exit_shell(String),
    "exec"   => ->execute(String),
    "export" => ->export(String),
    "grep"   => ->grep(String),
    "alias"  => ->shell_alias(String),
    "help"   => ->help(String),
  }

  def builtin?(program)
    LIST.has_key?(program)
  end

  def call_builtin(program : String, arguments : String)
    LIST[program].call(arguments)
  rescue err : Errno
    puts "crysh: error in builtin."
  end
end
