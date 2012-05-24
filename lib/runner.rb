require 'java'
require 'open3'

include_class %w(java.beans.PropertyChangeSupport)

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
    r = IO.popen(@command, 'r') do |out|
      while line = out.gets   # read the next line from stderr
        firePropertyChange("stdout", nil, line)
      end
    end
    @ret_val = $?
    firePropertyChange("done", nil, $?)
  rescue => e
    puts "Failed to run : #{e}"
    firePropertyChange("error", nil, e)
  end
end
