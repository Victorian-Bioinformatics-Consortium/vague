
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
    hbox.add(Box.createHorizontalGlue)
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
