# This file is part of : Vague - a GUI frontend for "velvet" a genomic sequence assembler
# Copyright (C) 2012 David R. Powell
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

require 'java'
require 'open3'

include_class %w(java.beans.PropertyChangeSupport
                 java.lang.ProcessBuilder
                )

class Runner < PropertyChangeSupport
  attr_reader :ret_val

  def initialize(command)
    @command = command
  end

  def start
    @thread = Thread.start do
      run
    end
  end

  def wait
    @thread.value
  end

  protected

  def run
    p = ProcessBuilder.new(@command).redirectErrorStream(true).start
    out = p.getInputStream.to_io
    while line = out.gets   # read the next line from stderr
      firePropertyChange("stdout", nil, line)
    end
    p.waitFor
    out.close
    @ret_val = p.exitValue
    firePropertyChange("done", nil, @ret_val)
  rescue => e
    puts "Failed to run : #{e}\n#{e.backtrace.join("\n")}"
    firePropertyChange("error", nil, e)
  end
end
