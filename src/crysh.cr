#!/usr/bin/crystal
require "./crysh/*"

# module Crysh
#
# end

STDIN.each_line do |line|
  pid = Process.fork {
    Process.exec line
  }

  pid.wait
  # puts line
end
