
class InputHandler
  # Create the actual jobs
  def self.interpret(input, initial_pgid)
    # Split input into commands
    commands = split_on_pipes(input)

    # pp commands

    # Add the gathered commands into a job
    job = Jobs.manager.add(Job.new(commands.size))
    commands.each_with_index do |command, index|
      job.add_command(command, index, commands.size)
    end

    # Wait for the whole job to finish, after each finish start clearing pipes
    job.processes.each_with_index do |proc, index|
      LibC.waitpid(proc.pid, out status_ptr, WUNTRACED)
      # Close this jobs pipes
      proc.close

      # pp "\nprocess ended with code: ", status_ptr

      unless job.processes.size == 1 || job.processes.size == index + 1
        job.@pipes[index][1].close
        job.@pipes[index][0].close
      end

      # 2 because this is second to last
      # if index + 2 >= job.processes.size
      #   # TODO this needs more detail to account for more pipes...
      #   # Kill all the pipes used for IPC in the pipeline
      #   job.@pipe_out.close
      # end


      puts("\nprocess ended with code: ", status_ptr) if debug?
      # Set the main process group of the shell to be in the foreground again
      LibC.tcsetpgrp(STDOUT.fd, initial_pgid) if initial_pgid
    end
  end
end
