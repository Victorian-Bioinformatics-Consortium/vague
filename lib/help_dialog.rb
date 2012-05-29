
include_class %w(javax.swing.JDialog
                 javax.swing.JEditorPane
                )

class HelpDialog < JDialog
  def initialize(parent)
    super(parent, "Vague help", true)
    help = java_class.resource("/lib/help.html") || java_class.resource("/lib/help.html")
    str = File.read(help.to_uri.to_s)

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
end
