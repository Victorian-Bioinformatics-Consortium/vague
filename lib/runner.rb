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
    out.close
    @ret_val = p.exitValue
    firePropertyChange("done", nil, @ret_val)
  rescue => e
    puts "Failed to run : #{e}"
    firePropertyChange("error", nil, e)
  end
end
