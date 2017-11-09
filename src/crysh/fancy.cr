def get_fancy
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

  return fancy
end
