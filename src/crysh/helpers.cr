# HELPERS
def load_history(fancy)
  if File.exists? HISTFILE # Does it exist?
    puts "Reading history from #{HISTFILE}" if debug?
    File.open(HISTFILE, "r") do |io| # Open the file.
      fancy.history.load io          # And load it into fancyline.
    end
  end
end

def save_history(fancy)
  File.open(HISTFILE, "w") do |io| # Open the file as writable
    fancy.history.save io          # And save.
  end
end

def spawn_program(program, arguments, placeholder_out, placeholder_in, first_proc)
  Process.fork {
    # if this is the first process in the job, its pid is the process group id
    if !first_proc
      LibC.setpgrp
      first_proc = Process.pid
    else # if first_proc isn't nil, it's value is the first process's pid.
      LibC.setpgid(Process.pid, first_proc)
    end

    unless placeholder_out == STDOUT
      STDOUT.reopen(placeholder_out)
      placeholder_out.close
    end

    unless placeholder_in == STDIN
      STDIN.reopen(placeholder_in)
      placeholder_in.close
    end
    begin
      Process.exec program, arguments
    rescue err : Errno
      puts "crysh: unknown command."
    end
  }
end

def split_on_pipes(line)
  # TODO below were my attempts to write a regex that would match only on pipes outside of quotes. I didn't succeed so far.
  # line.match(/([^"'|]+)|["']([^"']+)["']/).flatten.compact
  # line.scan(/([^"'|]+)|["']([^"']+)["']/)
  line.split('|')
end

def get_command(ctx)
  line = ctx.editor.line
  cursor = ctx.editor.cursor.clamp(0, line.size - 1)
  pipe = line.rindex('|', cursor)
  line = line[(pipe + 1)..-1] if pipe

  line.split.first?
end
