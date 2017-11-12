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
  end

  # Add a command to this job.
  def add_command(c : String, index : Int32)
    # c here is raw input, the args have not yet been seperated.
    @commands.push c
    # split makes an array delimited by " ".
    args = c.to_s.split
    # And then we shift the first element off, which represents the program to execute, removing it from args.
    program = args.shift
    # make sure program is a string.
    program = program.to_s
    p "Program: " + program if debug?

    if builtin? (program)
      # currently builtins except strings as args so we need to call args.join. TODO perhaps change this.
      call_builtin(program, args.join)
    else
      # First we need to set the placeholder file descriptors to some initial values
      if index + 1 < @commands.size
        @pipe = IO.pipe.to_a
        @placeholder_out = @pipe.last
      else
        @placeholder_out = STDOUT
      end

      # now we can attempt to spawn the process.
      @processes.push (spawn_process(program, args))
      p "Process:" if debug?
      pp @processes.last if debug?

      # Do some final cleaning up and closing of the FDs we had to open. Broken pipes are bad.
      @placeholder_out.close unless @placeholder_out == STDOUT
      @placeholder_in.close unless @placeholder_in == STDIN
      @placeholder_in = @pipe.first unless @pipe.empty?
    end
  end

  # Spawn/Exec a process in this job.
  def spawn_process(command, arguments)
    Process.fork {
      # if this is the first process in the job, its will make a new process group with its pid as the pgid.
      # this is very important as we will later tell the kernel that this process group needs to receive signals.
      # Will uncomment out soon. Job rewrite more important.
      # if @processes.size == 0
      #   LibC.setpgrp
      #   # set @pgid so we can set all the other processes in this job to use it as their pgid
      #   @pgid = Process.pid
      # else # every other process needs to be in process group @pgid
      #   LibC.setpgid(Process.pid, @pgid)
      # end

      unless @placeholder_out == STDOUT
        STDOUT.reopen(@placeholder_out)
        @placeholder_out.close
      end

      unless @placeholder_in == STDIN
        STDIN.reopen(@placeholder_in)
        @placeholder_in.close
      end

      # Try to exec the command. This mutates the crystal process that we'e forked into whatever command is.
      begin
        Process.exec command, arguments
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
