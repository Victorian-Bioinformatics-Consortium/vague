#!/usr/bin/env jruby --1.9 -w

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")
require 'java'
require "velvet_gui"

include_class %w(javax.swing.SwingUtilities)

# Anti-aliased fonts by default (make linux slightly less ugly)
System.setProperty("awt.useSystemAAFontSettings","on")
System.setProperty("swing.aatext", "true")


VelvetGUI.new.setVisible true

event_thread = nil
SwingUtilities.invokeAndWait { event_thread = java.lang.Thread.currentThread }
event_thread.join
