# This is a manager/singleton to hold jobs.
# TODO add bg, and actual bg/fg handling.
class Jobs
  @fg : Job?

  MANAGER = new

  def self.manager
    MANAGER
  end

  def initialize
    @list = [] of Job
  end

  def add(j : Job?)
    @list.push j
    return j
  end

  property fg, list
end
