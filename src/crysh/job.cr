require "./redirect_operator"

# NOTE: Detecting whether to execute a job as a unix command or a expression in Cryshlang.
# 1. Is the first argument a unix command or a builtin?
# 2. If so, process as a unix process
# 3. If not, process it as a Cryshlang expression
#
# A job is a collection of processes bound together by pipes, with the process group set to the pid of the first process.
class Job
  # Note, declaring vars here is the same as declaring them in the constructor, except you can also explicitly declare types here.
  # @placeholder_in : IO::FileDescriptor = STDIN
  # @placeholder_out : IO::FileDescriptor = STDOUT
  @pipe = [] of IO::FileDescriptor

  def run(commands, redirections)
    # Add commands to the job
    commands.each_with_index do |command, index|
      redirect = redirections[index]
      redirect = nil if redirect == ""
      next_command = (index+1 == commands.size) ? nil : commands[index+1]
      add_command(command, next_command, index, redirect, commands.size)
    end

    # Wait for the whole job to finish, after each finish start clearing pipes
    @processes.each_with_index do |proc, index|
      # If this command is doing < redirection, we need to kill these pipes right now
      # TODO: This is a bit of a hack... but not sure a better place to do this.
      redir_op = redirections[index]
      if redir_op
        if redir_op.redir.to_s == "<"
          @pipes[index][1].close
          @pipes[index][0].close
        end
      end

      LibC.waitpid(proc.pid, out status_ptr, WUNTRACED)

      # Close this jobs pipes
      proc.close

      unless @processes.size == 1 || @processes.size == index + 1
        @pipes[index][1].close
        @pipes[index][0].close
      end

      # Set the main process group of the shell to be in the foreground again
      LibC.tcsetpgrp(STDOUT.fd, Crysh::PGID) if Crysh::PGID
    end
  end

  def initialize(@pipe_length : Int32)
    @pipe_length -= 1
    # When a job is made, Strings are input representing the requested programs to launch.
    @commands = [] of String
    @redirs = [] of RedirectWithMod
    # And then they get turned into actual processes bound together by redirect operators.
    @processes = [] of Process
    # reader is 0, writer is 1
    @pipes = [] of Array(IO::FileDescriptor)

    if @pipe_length == 0
      # do nothing
    else
      @pipe_length.times do |n|
        # pipe usually returns a tuple, so we cast it to an array for conveinance
        @pipes << IO.pipe.to_a
      end
    end

    @pipe_in, @pipe_out = IO.pipe
  end

  # Add a command to this job.
  def add_command(c : String?, next_c : String?, index : Int32, redirect : RedirectWithMod?, pipe_length : Int32)
    return unless c

    # c here is raw input, the args have not yet been seperated.
    @commands.push c
    @redirs.push redirect if redirect
    # split makes an array delimited by " ".
    args = c.to_s.split
    # And then we shift the first element off, which represents the program to execute, removing it from args.
    program = args.shift
    # make sure program is a string.
    program = program.to_s

    if next_c
      next_cmd = next_c.to_s.split
      next_cmd = next_cmd.first
    else
      next_cmd = nil
    end

    p "Program: " + program if debug?

    if Builtin.builtin? (program)
      # currently builtins accept strings as args so we need to call args.join.
      # TODO this will need overhauling to make builtins work with nonbuiltins
      Builtin.call_builtin(program, args.join)
    else

      # now we can attempt to spawn the process.
      last_redir = @redirs[index-1] unless index == 0

      @processes.push(spawn_process(program, next_cmd, args, redirect, last_redir, pipe_length))

      p "Process:" if debug?
      pp @processes.last if debug?
    end
  end

  # Spawn/Exec a process in this job.
  def spawn_process(command, next_cmd, arguments, redirect, last_redir, pipe_length)
    Process.fork {
      set_process_group
      # Try to exec the command. This mutates this crystal process that we've forked into whatever command is.
      begin
        # First we need to check if this job only has one command, in which case no redirection is needed.
        if @pipes.size == 0
          Process.exec command, arguments
        else
          # Otherwise, we need to do io redirection.
          # First we turn the AST nodes we got back from the parser into a new class that we can use here.
          next_r, last_r = RedirectOperator.operators_for_job(redirect, last_redir)
          # Then we actually start spawning processes. The real magic happens in the method below.
          spawn_pipeline(next_r, last_r, command, arguments, next_cmd)
        end
      rescue err : Errno
        # Display a notice if executing the command failed.
        puts "crysh: unknown command."
        # TODO: there could be other reasons that exec fails, they might need to return more info to the user.
      end
    }
  end

  def spawn_pipeline(next_r : RedirectOperator?, last_r : RedirectOperator?, cmd : String, args : Array(String), next_cmd : String?)
    # n tracks our current place in the pipeline array
    n = first_command? ? 0 : @processes.size - 1

    case next_r
    when PipeOperator
      if first_command?
       Process.exec cmd, args, nil, false, false, STDIN, @pipes[n][1]
      else
       Process.exec cmd, args, nil, false, false, @pipes[n][0], @pipes[n+1][1]
      end
    when WriteOperator
      return unless next_cmd

      # Handle different types of IO redirection.
      # IE: make install 2> error.log
      mod_fd = next_r.@left_mod
      if mod_fd == "" || mod_fd.nil?
        mod_fd = 1
        left = IO::FileDescriptor.new(mod_fd)
      else
        left = File.open(mod_fd)
      end
      pp left

      fd = File.open(next_cmd, mode = "w")
      fd = @pipes[n][1].reopen(fd)

      if first_command?
        Process.exec cmd, args, nil, false, false, STDIN, @pipes[n][1]
      else
        Process.exec cmd, args, nil, false, false, @pipes[n][0], @pipes[n][1]
      end
    when ReadOperator
      if first_command?
        @pipes[n][1].close
        Process.exec cmd, args, nil, false, false, @pipes[n][0]
      else
        if last_r == "<"
          fd = File.read(cmd)
          @pipes[n][1] << fd
          @pipes[n][1].close
          @pipes[n][0].close
        end
      end
    else
      case last_r
      when PipeOperator
        Process.exec cmd, args, nil, false, false, @pipes[n][0]
      when WriteOperator
        fd = File.open(cmd, mode = "r")
        fd = @pipes[n][0].reopen(fd)
      when ReadOperator
        # TODO read until eof?
        fd = File.read(cmd)
        @pipes[n][1] << fd
        @pipes[n][1].close
        @pipes[n][0].close
      end
    end
  end

  def first_command?
    @processes.size == 0
  end

  def last_command?
    @processes.size == @pipe_length
  end

  def set_process_group
    # if this is the first process in the job, its will make a new process group with its pid as the pgid.
    # this is very important as we will later tell the kernel that this process group needs to receive signals.
    if @processes.size == 0
      LibC.setpgrp
      # set @pgid so we can set all the other processes in this job to use it as their pgid
      @pgid = Process.pid
    else
      # every other process needs to be in process group @pgid
      pid = @pgid
      LibC.setpgid(Process.pid, pid) if pid
    end
  end

  # Expose processes. This is Crystal's version of attr_accessor.
  property processes
end

