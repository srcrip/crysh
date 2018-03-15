# TODO these expansions are rudimentary and probably need some work.
def expand(input)
  input = expand_tilde(input)
  input = expand_vars(input)
  # input = substitute_sh(input)
end

ENV_REGEX = /(\$)(.+?(?=\/))/

def expand_vars(input)
  input.gsub(ENV_REGEX) do |str|
    ENV[str.lchop]
  end
end

TILDE_REGEX = /\~/

def expand_tilde(input)
  input.gsub(TILDE_REGEX) do |str|
    "$HOME/"
  end
end

SH_REGEX = /(\()(.*?)(\))/

# Expands things like (pwd) with sh
def substitute_sh(input)
  input.gsub(SH_REGEX) do |str|
    `#{str.lchop.rchop}`.strip
  end
end

BASH_REGEX = /\$(\()(.*?)(\))/

# TODO
# Expands things like $(pwd) with bash
# def substitute_bash(input)
# end
