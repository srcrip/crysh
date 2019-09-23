require "../../src/cltk/ast"
require "./scope"
require "./ast"
require "../crysh/job"

class Command
  def initialize(@commands : String?, @redirect : Redirect?)
  end

  def to_s
    puts "Commands:"
    pp @commands
    puts "Redirect?"
    pp @redirect
  end

  def commands
    @commands
  end
end

class Pipeline
  @commands : Array(Command)
  @job : Job

  def initialize(@commands = [] of Command)
    # Create the job
    @job = Jobs.manager.add(Job.new(@commands.size))

    # Run the jobs, by adding in commands to it
    @job.run(@commands.map(&.commands))
  end

  def to_s
    puts "Pipeline:"
    pp @commands
  end
end
