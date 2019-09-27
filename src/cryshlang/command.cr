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

  def redirect
    @redirect
  end
end

class Pipeline
  @commands : Array(Command)
  @job : Job

  def initialize(@commands = [] of Command)
    # Create the job
    @job = Jobs.manager.add(Job.new(@commands.size))

    # Run the jobs, by adding in commands to it
    @job.run(@commands.map(&.commands), @commands.map(&.redirect.to_s))
  end

  def to_s
    puts "Pipeline:"
    pp @commands
  end
end
