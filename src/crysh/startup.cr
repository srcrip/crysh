require "option_parser"

def is_crystal_on_path?
end

def startup
  # Parse options and flags on startup.
  parse_options

  # Exit if the user passed -c
  exit 0 unless interactive?
end

def parse_options
  OptionParser.parse! do |parser|
    parser.banner = "crysh: the crystal shell"
    parser.on("-c", "--command=COMMANDS", "Evaluate the specified commands and exit instead of entering interactive mode.") do |cmd|
      set_interactive false
      puts cmd
      # TODO implement command mode
    end
    parser.on("-d", "--debug", "Turns debug on mode for developers.") do
      set_debug
    end
    parser.on("-v", "--version", "Display version information and exit.") do
      puts VERSION
      exit 0
    end
    parser.on("-h", "--help", "Display this help message and exit.") do
      puts parser
      exit 0
    end
  end
end

# Could be expanded upon for plugins? TODO
def on_startup
end
