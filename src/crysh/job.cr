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
      if redirections[index] == "<"
        @pipes[index][1].close
        @pipes[index][0].close
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
    @redirs = [] of String
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
  def add_command(c : String?, next_c : String?, index : Int32, redirect : String?, pipe_length : Int32)
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

      # pp @processes.last

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
        ##
        ## IO Redirection time
        ##
        # First we need to check if this job only has one command, in which case no redirection is needed.
        if @pipes.size == 0
          Process.exec command, arguments
        else
          if redirect == "|" || last_redir == "|"
            spawn_with_pipe command, next_cmd, arguments, redirect, last_redir, pipe_length
          elsif redirect == ">" || last_redir == ">"
            spawn_with_gt command, next_cmd, arguments, redirect, last_redir, pipe_length
          elsif redirect == "<" || last_redir == "<"
            spawn_with_lt command, next_cmd, arguments, redirect, last_redir, pipe_length
          end
        end
      rescue err : Errno
        # Display a notice if executing the command failed.
        puts "crysh: unknown command."
        # TODO: there could be other reasons that exec fails, they might need to return more info to the user.
      end
    }
  end


  # This is for redirection > way
  def spawn_with_gt(command, next_cmd, arguments, redirect, last_redir, pipe_length)
    n = @processes.size - 1

    if next_cmd
      if redirect == ">"
        fd = File.open(next_cmd, mode = "w")
        fd = @pipes[n][1].reopen(fd)

        if @processes.size == 0 # If this is the first command in the job
          n = 0
          Process.exec command, arguments, nil, false, false, STDIN, @pipes[n][1]
        elsif @processes.size + 1 == pipe_length # if this is the last
          Process.exec command, arguments, nil, false, false, @pipes[n][0], @pipes[n][1]
        else # if this is a command in the middle
          Process.exec command, arguments, nil, false, false, @pipes[n][0], @pipes[n+1][1]
        end

      elsif last_redir == ">"
        fd = File.open(command, mode = "r")
        fd = @pipes[n][0].reopen(fd)
      end
    end
  end

  # This is for redirection < way
  def spawn_with_lt(command, next_cmd, arguments, redirect, last_redir, pipe_length)
    n = @processes.size - 1

    if @processes.size == 0 # If this is the first command in the job
      n = 0
      @pipes[n][1].close
      Process.exec command, arguments, nil, false, false, @pipes[n][0]
    elsif last_redir == "<"
      # TODO read until eof?



      @pipes[n][0].close
    end
  end

  # This is classic pipe redirection
  def spawn_with_pipe(command, next_cmd, arguments, redirect, last_redir, pipe_length)
    n = @processes.size - 1

    if next_cmd
      if redirect == ">"
        if @processes.size == 0 # If this is the first command in the job
          n = 0
          fd = File.open(next_cmd, mode = "w")
          fd = @pipes[n][1].reopen(fd)
          Process.exec command, arguments, nil, false, false, STDIN, @pipes[n][1]
        else # if this is a command in the middle
          fd = File.open(next_cmd, mode = "w")
          fd = @pipes[n+1][1].reopen(fd)
          Process.exec command, arguments, nil, false, false, @pipes[n][0], @pipes[n+1][1]
        end
      else
        if @processes.size == 0 # If this is the first command in the job
          n = 0
          Process.exec command, arguments, nil, false, false, STDIN, @pipes[n][1]
        else # if this is a command in the middle
          Process.exec command, arguments, nil, false, false, @pipes[n][0], @pipes[n+1][1]
        end
      end
    else # if this is the last
      Process.exec command, arguments, nil, false, false, @pipes[n][0]
    end
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
