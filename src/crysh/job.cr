# NOTE: Detecting whether to execute a job as a unix command or a expression in Cryshlang.
# 1. Is the first argument a unix command or a builtin?
# 2. If so, process as a unix process
# 3. If not, process it as a Cryshlang expression
#
# A job is a collection of processes bound together by pipes, with the process group set to the pid of the first process.
class Job
  # Note, declaring vars here is the same as declaring them in the constructor, except you can also explicitly declare types here.
  @placeholder_in : IO::FileDescriptor = STDIN
  @placeholder_out : IO::FileDescriptor = STDOUT
  @pipe = [] of IO::FileDescriptor

  def initialize
    # When a job is made, Strings are input representing the requested programs to launch.
    @commands = [] of String
    # And then they get turned into actual processes bound together by pipes.
    @processes = [] of Process

    @pipe_in, @pipe_out = IO.pipe
  end

  # Add a command to this job.
  # def add_command(lang, c : String, index : Int32)
  def add_command(c : String, index : Int32, pipe_length : Int32)
    # c here is raw input, the args have not yet been seperated.
    @commands.push c
    # split makes an array delimited by " ".
    args = c.to_s.split
    # And then we shift the first element off, which represents the program to execute, removing it from args.
    program = args.shift
    # make sure program is a string.
    program = program.to_s
    p "Program: " + program if debug?

    if Builtin.builtin? (program)
      # currently builtins accept strings as args so we need to call args.join. TODO perhaps change this.
      Builtin.call_builtin(program, args.join)
    else
      # First we need to set the placeholder file descriptors to some initial values
      if index + 1 < pipe_length
        @pipe = IO.pipe.to_a
        @placeholder_out = @pipe.last
      else
        @placeholder_out = STDOUT
      end

      # now we can attempt to spawn the process.
      @processes.push(spawn_process(program, args, pipe_length))

      p "Process:" if debug?
      pp @processes.last if debug?

      # Do some final cleaning up and closing of the FDs we had to open. Broken pipes are bad.
      # @placeholder_out.close unless @placeholder_out == STDOUT
      # @placeholder_in.close unless @placeholder_in == STDIN
      # @placeholder_in = @pipe.first unless @pipe.empty?
    end
  end

  # Spawn/Exec a process in this job.
  def spawn_process(command, arguments, pipe_length)
    Process.fork {
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

      # unless @placeholder_out == STDOUT
      #   STDOUT.reopen(@placeholder_out)
      #   @placeholder_out.close
      # end

      # unless @placeholder_in == STDIN
      #   STDIN.reopen(@placeholder_in)
      #   @placeholder_in.close
      # end

      # TODO
      # close fds at /proc/$pid/fd/0


      # Try to exec the command. This mutates this crystal process that we've forked into whatever command is.
      begin
        # if this is last command in the pipeline, don't redirect out
        if @processes.size + 1 == pipe_length
          Process.exec command, arguments, nil, false, false, @pipe_in
        # if this is first command, don't redirect in
        elsif @processes.size == 0
          Process.exec command, arguments, nil, false, false, STDIN, @pipe_out
        else
          Process.exec command, arguments, nil, false, false, @pipe_in, @pipe_out
        end
      rescue err : Errno
        # Display a notice if executing the command failed.
        puts "crysh: unknown command."
        # TODO: there could be other reasons that exec fails, they might need to return more info to the user.
      end
    }
  end

  # Expose processes. This is Crystal's version of attr_accessor.
  property processes
end
