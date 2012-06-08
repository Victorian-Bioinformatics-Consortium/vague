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


include_class %w(javax.swing.JDialog
                 javax.swing.JEditorPane
                )

class HelpDialog < JDialog
  def initialize(parent)
    super(parent, "Vague help", true)
    help = java_class.resource_as_stream("/vague/lib/help.html") || java_class.resource_as_stream("/lib/help.html")
    str = read_file(help)

    vbox = Box.createVerticalBox

    txt = JEditorPane.new("text/html", str)
    txt.editable = false

    vbox.add(JScrollPane.new(txt))

    vbox.add(hbox = Box.createHorizontalBox)
    #hbox.add(Box.createHorizontalGlue)
    hbox.add(but = JButton.new("Ok"))
    but.add_action_listener {|e| self.setVisible(false) }

    txt.setCaretPosition(0)
    setContentPane(vbox)
    pack
    setSize 400,500
    setLocationRelativeTo(parent)
    setVisible(true)
  end

  def read_file(file)
    res = ""
    br = java.io.BufferedReader.new(java.io.InputStreamReader.new(file))
    while (line = br.read_line())
      res += line
    end
    res
  end

end
