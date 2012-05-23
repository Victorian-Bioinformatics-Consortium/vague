#!/usr/bin/env jruby --1.9 -w

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")
require 'java'
require "velvet_gui"

include_class %w(javax.swing.SwingUtilities)


VelvetGUI.new.setVisible true

event_thread = nil
SwingUtilities.invokeAndWait { event_thread = java.lang.Thread.currentThread }
event_thread.join
