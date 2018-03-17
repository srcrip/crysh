# These are the defaults for functions that you can overwrite using themes and plugins.
# If for some reason a file for a theme can't be found, these will be used as backups.

def crysh_prompt
  dir = Dir.current.colorize(:red).to_s
  user = ENV["USER"].colorize(:yellow).to_s
  hostname = System.hostname.colorize(:green).to_s
  prompt_line = "❯ ".colorize(:blue).to_s
  prompt_string = "\r\n" + user + " at " + hostname + " in " + dir + "\r\n" + prompt_line
end
