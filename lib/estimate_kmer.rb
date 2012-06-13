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

require 'shellwords'

include_class %w(javax.swing.JDialog
                 javax.swing.JEditorPane
                 javax.swing.SwingUtilities
                 javax.swing.JProgressBar
                )

class EstimateKmer < JDialog
  attr_reader :result

  include GridBag
  def initialize(parent, path, files)
    super(SwingUtilities.windowForComponent(parent), "K-mer estimator", true)
    @files = files
    @path = path
    initGridBag

    gb_set_tip("Size of target genome (suffixes k,m,g supported).  eg. 300m")
    add_gb(JLabel.new("Target genome size: "))
    add_gb(@size = JTextField.new(8), :gridwidth => :remainder)
    gb_set_tip("Target k-mer coverage")
    add_gb(JLabel.new("Desired k-mer coverage: "))
    add_gb(@cov = JTextField.new("25"), :gridwidth => :remainder)
    gb_set_tip("Number of files you have specified")
    add_gb(JLabel.new("Number of read files: "))
    add_gb(JLabel.new(@files.length.to_s), :gridwidth => :remainder)
    gb_set_tip(nil)

    add_gb(@progbar = JProgressBar.new, :gridwidth => :remainder)
    @progbar.visible = false

    add_gb(Box.createVerticalStrut(10), :gridwidth => :remainder)

    hbox = Box.createHorizontalBox
    hbox.add(Box.createHorizontalGlue)
    hbox.add(cancel = JButton.new("Cancel"))
    hbox.add(Box.createHorizontalGlue)
    hbox.add(@est_but = JButton.new("Estimate!"))
    hbox.add(Box.createHorizontalGlue)
    add_gb(hbox, :gridwidth => :remainder)

    cancel.add_action_listener {|e| setVisible(false)}
    @est_but.add_action_listener {|e| estimate }

    pack
    setSize 350,150
    setLocationRelativeTo(parent)
    setVisible(true)
  end

  def exe
    prog = "velvetk.pl"
    if @path && File.executable?(File.join(@path, prog))
      prog = File.join(@path, prog)
    end
    prog
  end

  def run_failed
    JOptionPane.showMessageDialog(self, "Error running velvetk.pl", "Error", JOptionPane::ERROR_MESSAGE)
    setVisible(false)
  end

  def estimate
    @progbar.setIndeterminate(true)
    @progbar.visible = true

    cmd = [exe,"--size=#{@size.text}","--cov=#{@cov.text}", "--best"] + @files

    @est_but.enabled = false
    runner = Runner.new(cmd)
    runner.add_property_change_listener('stdout') {|e| @result = e.new_value}
    runner.add_property_change_listener('error') {|e| run_failed }
    runner.add_property_change_listener('done') do |e|
      if e.new_value == 0
        setVisible(false)
      else
        run_failed
      end
    end
    runner.start
  end
end
