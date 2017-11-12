# This is an example of how you can get the output of system commands right from crystal.
# You could do similar things in other languages in your own functions. Or even use bash shell scripting.
# Run 'crystal build crysh_prompt' to make a new binary from this file.
Process.run("pwd", args = nil, env = nil, clear_env = false, shell = false, input = false, output = STDOUT)
puts "❯ "
