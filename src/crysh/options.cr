# These are global flags used throughout the program. For actual options/flags parsing at startup, see src/startup.cr
# TODO while I wrote this I was very confused that you couldn't just have top level @@class_vars in Crystal. You might be able to just define vars like self.var at the top level of a module though, I haven't checked yet. That would make this a lot cleaner.
module Options
  class Interactive
    # By default, crysh starts in interactive mode. Pass -c to force command mode.
    @@setting = true

    def self.true?
      @@setting
    end

    def self.set(val = true)
      @@setting = val
    end
  end

  class Debug
    # By default, crysh starts with debug off. Pass -d to force debug mode on.
    @@setting = false

    def self.true?
      @@setting
    end

    def self.set(val = true)
      @@setting = val
    end
  end

  def interactive?
    Interactive.true?
  end

  def set_interactive(val = true)
    Interactive.set(val)
  end

  def debug?
    Debug.true?
  end

  def set_debug(val = true)
    Debug.set(val)
  end
end
