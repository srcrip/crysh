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

def get_command(ctx)
  line = ctx.editor.line
  cursor = ctx.editor.cursor.clamp(0, line.size - 1)
  pipe = line.rindex('|', cursor)
  line = line[(pipe + 1)..-1] if pipe

  line.split.first?
end
