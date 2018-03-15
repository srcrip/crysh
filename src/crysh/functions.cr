# These are the defaults for functions that you can overwrite using themes and plugins.

# Do any printing to the screen and then return the string that will get sent to fancyline.
def crysh_prompt
  hostname = System.hostname.colorize(:red)
  user = ENV["USER"]
  dir = Dir.current
  puts "\n"
  puts user + " at " + hostname + " in " + Dir.current
  return "❯ "
end
