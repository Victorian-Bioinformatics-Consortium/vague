#!/usr/bin/env jruby --1.9 -w

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
