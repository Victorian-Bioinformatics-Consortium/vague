include_class %w(javax.swing.JDialog
                 javax.swing.JEditorPane
                 javax.swing.SwingUtilities
                )

class EstimateKmer < JDialog
  include GridBag
  def initialize(parent)
    super(SwingUtilities.windowForComponent(parent), "K-mer estimator", true)
    initGridBag

    add_gb(JLabel.new("Target genome size: "))
    add_gb(@size = JTextField.new(8), :gridwidth => :remainder)
    add_gb(JLabel.new("Desired k-mer coverage: "))
    add_gb(@cov = JTextField.new("25"), :gridwidth => :remainder)

    hbox = Box.createHorizontalBox
    hbox.add(Box.createHorizontalGlue)
    hbox.add(est_but = JButton.new("Estimate!"))
    hbox.add(cancel = JButton.new("Cancel"))
    hbox.add(Box.createHorizontalGlue)
    add_gb(hbox)

    cancel.add_action_listener {|e| setVisible(false)}
    est_but.add_action_listener {|e| estimate ; setVisible(false) }

    pack
    setSize 350,150
    setLocationRelativeTo(parent)
    setVisible(true)
  end

  def estimate
    puts "Size=#{@size.text} cov=#{@cov.text}"
  end
end
