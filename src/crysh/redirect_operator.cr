class RedirectOperator
  def initialize(@left_mod : String?, @right_mod : String?)
  end

  def self.operator(input)
    return unless input

    case input.redir.to_s
    when "|"
      PipeOperator
    when ">"
      WriteOperator
    when "<"
      ReadOperator
    else
      nil
    end
  end

  def self.operators_for_job(next_r, last_r)
    next_r_class = RedirectOperator.operator(next_r)
    last_r_class = RedirectOperator.operator(last_r)


    return RedirectOperator.init_class(next_r_class, next_r), RedirectOperator.init_class(last_r_class, last_r)
  end

  def self.init_class(r_class, r)
    unless r_class.nil?
      left_mod  = r ? r.left_mod.to_s  : nil
      right_mod = r ? r.right_mod.to_s : nil

      if r_class == PipeOperator
        r_class.new(nil, nil)
      else
        r_class.new(left_mod, right_mod)
      end
    end
  end
end

class PipeOperator < RedirectOperator
  def initialize(@left_mod = nil, @right_mod = nil)
  end
end

class WriteOperator < RedirectOperator
  def initialize(@left_mod : String?, @right_mod : String?)
  end
end

class ReadOperator < RedirectOperator
  def initialize(@left_mod : String?, @right_mod : String?)
  end
end
