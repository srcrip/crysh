#!/usr/bin/crystal
require "./crysh/*"

# module Crysh
#
# end

STDIN.each_line do |line|
  pid = fork {
    exec line
  }

  Process.wait pid
end
