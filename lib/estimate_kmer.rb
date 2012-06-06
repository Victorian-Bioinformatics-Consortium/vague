require 'shellwords'

include_class %w(javax.swing.JDialog
                 javax.swing.JEditorPane
                 javax.swing.SwingUtilities
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

  def backticks(args)
    cmd = args.map{|s| Shellwords::escape s}.join ' '
    p cmd
    `#{cmd}`
  end

  def exe
    if @path
      File.join(@path,"velvetk.pl")
    else
      "velvetk.pl"
    end
  end

  def estimate
    cmd = [exe,"--size=#{@size.text}","--cov=#{@cov.text}", "--best"] + @files
    resp = backticks(cmd)
    if $? != 0
      JOptionPane.showMessageDialog(self, "Error running velvetk.pl", "Error",
                                    JOptionPane::ERROR_MESSAGE)
    end
    puts resp
    @result = resp
  end
end
