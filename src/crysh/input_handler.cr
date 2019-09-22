
class InputHandler
  # Create the actual jobs
  def self.interpret(input, initial_pgid)
    # Split input into commands
    commands = split_on_pipes(input)

    # Add the gathered commands into a job
    job = Jobs.manager.add(Job.new)
    commands.each_with_index do |command, index|
      # job.add_command(lang, command, index)
      job.add_command(command, index, commands.size)
    end

    # job.processes.each_with_index do |proc, index|
    #   if index + 1 == job.processes.size
    #     # nothing
    #   else
    #     reader, writer = IO.pipe
    #     proc.output = IO::Redirect::Pipe
    #     proc.output = writer
    #     job.processes[index+1].input = reader
    #   end
    # end

    # Wait for the whole job to finish before completing the loop
    job.processes.each do |proc|
      LibC.waitpid(proc.pid, out status_ptr, WUNTRACED)
      pp status_ptr if debug?
      # puts("\nprocess ended with code: ", status_ptr)
      LibC.tcsetpgrp(STDOUT.fd, initial_pgid) if initial_pgid
    end
  end
end
