require "./crysh/*"
require "colorize"
require "fancyline"

HISTFILE = "#{Dir.current}/history.log"
DEBUG    = true
# prompt = "❯ ".colorize(:blue)
prompt = "❯ "

# BUILTINS
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

# HELPERS
def spawn_program(program, arguments, placeholder_out, placeholder_in)
  Process.fork {
    unless placeholder_out == STDOUT
      STDOUT.reopen(placeholder_out)
      placeholder_out.close
    end

    unless placeholder_in == STDIN
      STDIN.reopen(placeholder_in)
      placeholder_in.close
    end

    Process.exec program, arguments
  }
end

def split_on_pipes(line)
  # line.match(/([^"'|]+)|["']([^"']+)["']/).flatten.compact
  # line.scan(/([^"'|]+)|["']([^"']+)["']/)
  line.split('|')
end

def builtin?(program)
  BUILTINS.has_key?(program)
end

def call_builtin(program, arguments)
  BUILTINS[program].call(arguments)
end

BUILTINS = {
  "cd"     => ->cd (String),
  "exit"   => ->exit (String),
  "exec"   => ->exec (String),
  "export" => ->export (String),
}

fancy = Fancyline.new

fancy.display.add do |ctx, line, yielder|
  # We underline command names
  line = line.gsub(/^\w+/, &.colorize.mode(:underline))
  line = line.gsub(/(\|\s*)(\w+)/) do
    "#{$1}#{$2.colorize.mode(:underline)}"
  end

  # And turn --arguments green
  line = line.gsub(/--?\w+/, &.colorize(:green))

  # Then we call the next middleware with the modified line
  yielder.call ctx, line
end

fancy.actions.set Fancyline::Key::Control::AltH do |ctx|
  if command = get_command(ctx) # Figure out the current command
    system("man #{command}")    # And open the man-page of it
  end
end

fancy.sub_info.add do |ctx, yielder|
  lines = yielder.call(ctx) # First run the next part of the middleware chain

  if command = get_command(ctx) # Grab the command
    help_line = `whatis #{command} 2> /dev/null`.lines.first?
    lines << help_line if help_line # Display it if we got something
  end

  lines # Return the lines so far
end

fancy.autocomplete.add do |ctx, range, word, yielder|
  completions = yielder.call(ctx, range, word)

  # The `word` may not suffice for us here.  It'd be fine however for command
  # name completion.

  # Find the range of the current path name near the cursor.
  prev_char = ctx.editor.line[ctx.editor.cursor - 1]?
  if !word.empty? || {'/', '.'}.includes?(prev_char)
    # Then we try to find where it begins and ends
    arg_begin = ctx.editor.line.rindex(' ', ctx.editor.cursor - 1) || 0
    arg_end = ctx.editor.line.index(' ', arg_begin + 1) || ctx.editor.line.size
    range = (arg_begin + 1)...arg_end

    # And using that range we just built, we can find the path the user entered
    path = ctx.editor.line[range].strip
  end

  # Find suggestions and append them to the completions array.
  Dir["#{path}*"].each do |suggestion|
    base = File.basename(suggestion)
    suggestion += '/' if Dir.exists? suggestion
    completions << Fancyline::Completion.new(range, suggestion, base)
  end

  completions
end

def get_command(ctx)
  line = ctx.editor.line
  cursor = ctx.editor.cursor.clamp(0, line.size - 1)
  pipe = line.rindex('|', cursor)
  line = line[(pipe + 1)..-1] if pipe

  line.split.first?
end

begin # Get rid of stacktrace on ^C
  loop do
    # print prompt
    input = fancy.readline(prompt.to_s)

    if input
      # strip the newline character from input
      input = input.strip

      commands = split_on_pipes(input)
      pp commands

      placeholder_in = STDIN
      placeholder_out = STDOUT
      pipe = [] of IO::FileDescriptor

      processes = [] of Process

      commands.each_with_index do |command, index|
        args = command.to_s.split
        program = args.shift

        p "Program: " + program if DEBUG

        if builtin? (program.to_s)
          call_builtin(program.to_s, args.join)
        else
          if index + 1 < commands.size
            pipe = IO.pipe
            placeholder_out = pipe.last
          else
            placeholder_out = STDOUT
          end

          processes.push spawn_program(program, args, placeholder_out, placeholder_in)

          # p pipe.empty?

          placeholder_out.close unless placeholder_out == STDOUT
          placeholder_in.close unless placeholder_in == STDIN
          placeholder_in = pipe.first unless pipe.empty?
        end
      end

      processes.each(&.wait)

      # if BUILTINS.has_key? command.to_s
      #   BUILTINS[command.to_s].call(args.join)
      # else
      #   pid = Process.fork {
      #     Process.exec line
      #   }

      #   pid.wait
      # end
    end
  end
rescue err : Fancyline::Interrupt
  puts "Exited Crysh ok."
end

File.open(HISTFILE, "w") do |io| # So open it writable
  fancy.history.save io          # And save.  That's it.
end
