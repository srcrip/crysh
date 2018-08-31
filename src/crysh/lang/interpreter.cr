require "./ast"

# The interpreter traverses the AST and call's functions from Crysh.
class Interpreter
  macro on(klass, &block)
    def wrapped_visit({{block.args.first}} : {{klass.id}})
      {{block.body}}
    end
  end

  def wrapped_visit(item)
    raise "no patterns defined for #{item} (#{item.class})"
  end

  alias VarTable = Float64 | String | Bool | Expression
  # Variables at top-level state
  @@vars = {} of String => VarTable
  # The environment is a series of frames with variables, at varying levels of the stack
  @@env = {} of String => VarTable
  # Prototypes point to function definitions and hold their arguments
  @@protos = {} of String => Array(String)
  # Functions hold lists of expressions that can be interpreted by the Call node
  @@functions = {} of String => Array(Expression)

  def visit(node)
    wrapped_visit(node)
  end

  def eval(ast)
    visit ast
  end

  on ANumber do |node|
    node.value
  end

  on Call do |node|
    callee = @@functions[node.name]?
    if !callee
      raise "Unknown function referenced."
    end
    if callee.size != node.args.size
      raise "Function #{node.name} expected #{callee.size} argument(s) but was called with #{node.args.size}."
    end

    pp callee

    # Define the variables into the environment based on arguments
    node.args.map { |arg|
      # visit arg
      pp arg
    }

    # Call the function now by interpreting its body
    @@functions[node.name].tap do |body|
      case body
      when ExpressionList
        expressions = body.expressions
        expressions.each_with_index do |expression, index|
          if index < (expressions.size - 1)
            visit expression
          end
        end
      else
        visit body
      end
    end
  end

  on Binary do |node|
    left = visit node.left
    right = visit node.right

    case node
    when Eql
      left == right
    when Assign
      puts "woh!"
    when Add
      if left.is_a? Float64 && right.is_a? Float64
        left + right
      end
    when Sub
      if left.is_a? Float64 && right.is_a? Float64
        left - right
      end
    when Div
      if left.is_a? Float64 && right.is_a? Float64
        left / right
      end
    when Mul
      if left.is_a? Float64 && right.is_a? Float64
        left * right
      end
    when LT
      if left.is_a? Float64 && right.is_a? Float64
        left < right
      end
    when GT
      if left.is_a? Float64 && right.is_a? Float64
        left > right
      end
    when Or
      left || right
    when And
      left && right
    else
      right
    end
  end

  on Assign do |node|
    r = node.right.as(ANumber)
    @@vars[node.name] = r.value
  end

  on Variable do |node|
    if @@vars[node.name]?
      puts @@vars[node.name]
      @@vars[node.name]
    else
      raise "Unitialized variable \"#{node.name}\"."
    end
  end

  on Prototype do |node|
    puts "proto"
    if @@protos[node.name]?
      # get function if it's already defined
      @@protos[node.name]
    else
      # add function, if not
      @@protos[node.name] = node.arg_names
    end
  end

  on Function do |node|
    puts "function"
    # Reset the symbol table?
    # @st.clear

    # Translate the function's prototype.
    proto = visit node.proto.as(Prototype)

    pp node.body.class
    # @@functions[node.proto.name] = node.body.as(Array(Expression))

    # params = func.each do |p|
    #   # set values
    # end
    # func.params.to_a.each do |param|
    #   @st[param.name] = alloca @ctx.float, param.name
    #   store param, @st[param.name]
    # end

    # Create a new basic block to insert into, allocate space for
    # the arguments, store their values, translate the expression,
    # and set its value as the return value.
    # body = node.body
    # case body
    # when ExpressionList
    #   expressions = body.expressions
    #   expressions.each_with_index do |expression, index|
    #     if index < (expressions.size - 1)
    #       visit expression
    #     else
    #       # Return?
    #       visit(expression)
    #     end
    #   end
    # else
    #   # Return?
    #   visit(body)
    # end

    # body = node.body
    # @@functions[func.name] = ->(params) {
    #   case body
    #   when ExpressionList
    #     expressions = body.expressions
    #     expressions.each_with_index do |expression, index|
    #       if index < (expressions.size - 1)
    #         visit expression
    #       end
    #     end
    #   else
    #     visit body
    #   end
    # }

    proto
  end
end
