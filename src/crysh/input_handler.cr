# A wrapper for creating jobs.
class InputHandler
  # Create the actual jobs
  def self.interpret(input, initial_pgid)
    # Split input into commands
    commands = split_on_pipes(input)

    # Add the gathered commands into a job
    job = Jobs.manager.add(Job.new)
    commands.each_with_index do |command, index|
      # job.add_command(lang, command, index)
      job.add_command(command, index)
    end

    # Wait for the whole job to finish before completing the loop
    job.processes.each do |proc|
      LibC.waitpid(proc.pid, out status_ptr, WUNTRACED)
      pp status_ptr if debug?
      print("process ended with code: ", status_ptr)
      pp "Done"
      LibC.tcsetpgrp(STDOUT.fd, initial_pgid) if initial_pgid
    end
    # LibC.tcsetpgrp(STDOUT.fd, Process.pgid) if Process.pgid
  end
end
