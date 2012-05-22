require 'java'
require 'gridbag'
require 'velvet_binary'
require 'guess_fasta_type'

include_class %w(java.awt.event.ActionListener
                 java.awt.BorderLayout
                 java.awt.GridBagLayout
                 java.awt.GridBagConstraints
                 java.awt.Dimension
                 java.lang.System
                 java.util.prefs.Preferences
                 javax.swing.JOptionPane
                 javax.swing.SwingUtilities
                 javax.swing.JButton
                 javax.swing.JFrame
                 javax.swing.JLabel
                 javax.swing.JTextField
                 javax.swing.JComponent
                 javax.swing.JComboBox
                 javax.swing.JCheckBox
                 javax.swing.Box
                 javax.swing.BoxLayout
                 javax.swing.JFileChooser
                 javax.swing.JButton
                 javax.swing.ImageIcon
                 javax.swing.JScrollPane
                 javax.swing.border.TitledBorder
                )

class Settings
  def self.prefs
    @prefs ||= Preferences.userNodeForPackage(self);
  end

  def self.velvet_directory
    prefs.get("velvet_directory", "")
  end

  def self.velvet_directory=(str)
    prefs.put("velvet_directory", str)
  end

end

class FileSelector < JComponent
  include GridBag
  def initialize(num)
    super()
    setBorder(TitledBorder.new("Channel #{num} Sequences"))
    initGridBag

    add_gb(JLabel.new("Read type: "), :gridwidth => 1, :fill => :horizontal, :anchor => :northwest)
    add_gb(@typ = JComboBox.new(["single","paired end","mate pair"].to_java), :gridwidth => :remainder, :fill => :none)
    add_gb(@intLbl = JLabel.new("Interleaved sequence file: "), :gridwidth => 1, :fill => :horizontal)
    add_gb(@interleaved = JComboBox.new(["interleaved","separate"].to_java), :gridwidth => :remainder, :fill => :none)

    add_gb(@file1Lbl = JLabel.new("Sequence file: "), :gridwidth => 1, :fill => :horizontal)
    add_gb(@file1 = JTextField.new, :weightx => 1)
    add_gb(@file1Btn = JButton.new("..."), :gridwidth => :remainder, :weightx => 0)

    add_gb(@file2Lbl = JLabel.new("Right Sequence file: "), :gridwidth => 1)
    add_gb(@file2 = JTextField.new, :weightx => 1)
    add_gb(@file2Btn = JButton.new("..."), :gridwidth => :remainder, :weightx => 0)

    add_gb(JLabel.new("Format: "), :gridwidth => 1)
    add_gb(@fmt = JComboBox.new(["fasta","fastq","fasta.gz","fastq.gz"].to_java), :gridwidth => 1, :fill => :none)

    @typ.add_action_listener {|e| update_boxes }
    @interleaved.add_action_listener {|e| update_boxes }
    @file1Btn.add_action_listener {|e| select_file(@file1) }
    @file2Btn.add_action_listener {|e| select_file(@file2) }
    update_boxes
  end

  def default_dir(fld)
    [fld.text, @file1.text, @file2.text].reject(&:empty?).first
  end

  def select_file(fileField)
    fc=JFileChooser.new(default_dir(fileField))
    if fc.showOpenDialog(fileField)==0
      file = fc.getSelectedFile.getPath
      fileField.set_text file
      t = GuessFastaType.guess(file)
      @fmt.selected_item = t.to_s.sub('_','.')
    end
  end

  def separate_files
    @interleaved.visible && @interleaved.selected_item == 'separate'
  end

  def update_boxes
    @interleaved.visible = @intLbl.visible = (@typ.selected_item != "single")
    @file2Lbl.visible = @file2.visible = @file2Btn.visible = separate_files
    @file1Lbl.text = @file2Lbl.visible? ? "Left Sequence file: " : "Sequence file: "
    revalidate
  end

  def read_type
    case @typ.selected_item
    when 'single': 'short'
    when 'paired end': 'shortPaired'
    else 'longPaired'
    end
  end

  def to_command_line(n)
    if separate_files
      ["-separate","-"+@fmt.selected_item, "-#{read_type}#{n}", @file1.text, @file2.text]
    else
      ["-interleaved","-"+@fmt.selected_item, "-#{read_type}#{n}", @file1.text]
    end
  end

  def valid_files
    File.exists?(@file1.text)
  end
end

class FilesSelector < JComponent
  def initialize
    super
    @selectors = []
    setLayout BorderLayout.new

    add(@vbox = Box.createVerticalBox)
    add_channel
  end

  def del_channel
    sel = @selectors.pop
    @vbox.remove sel
    validate
  end

  def add_channel
    @vbox.add(sel = FileSelector.new(@selectors.length+1))
    @selectors << sel
    validate
  end

  def num_channels
    @selectors.length
  end

  def valid_files
    @selectors.all?(&:valid_files)
  end

  def to_command_line
    ret=[]
    @selectors.each_with_index do |fileSel, i|
      ret << fileSel.to_command_line(i+1)
    end
    ret.flatten
  end
end

class OptionList < JComponent
  include GridBag
  def initialize(options)
    super()
    initGridBag
    setBorder(TitledBorder.new("Advanced Options"))

    options.each do |opt|
      add_gb(l = JLabel.new(opt.name), :gridwidth=>1, :weightx=>0, :fill => :horizontal)
      l.setToolTipText opt.desc

      add_gb(tf = create_editor(opt), :gridwidth=>:remainder, :weightx=>1, :fill => :horizontal)
    end
  end

  def create_editor(opt)
    w=nil
    case opt.type
    when 'yes|no', 'flag':
      w = JCheckBox.new
      w.setToolTipText opt.desc
      w.add_change_listener {|e| w.selected? ? opt.value='yes' : opt.value='no'}
    else
      w = JTextField.new(opt.value)
      w.setToolTipText opt.desc
      w.get_document.add_document_listener {|e| opt.value = w.getText}
    end
    w
  end
end

class MainOptions < JComponent
  include GridBag
  def initialize()
    super()
    initGridBag
    setBorder(TitledBorder.new("Main Options"))

    add_gb(JLabel.new("Output Directory: "), :gridwidth => 1, :fill => :horizontal, :anchor => :northwest, :weightx=>0)
    add_gb(@file1 = JTextField.new, :weightx => 1, :gridwidth=>2)
    add_gb(file1Btn = JButton.new("..."), :gridwidth => :remainder, :weightx => 0)
    file1Btn.add_action_listener {|e| select_file(@file1) }

    add_gb(JLabel.new("Hash Length: "), :gridwidth => 1, :fill => :horizontal, :weightx=>0)
    add_gb(@hash_length = JComboBox.new((1..31).step(2).to_a.to_java), :gridwidth=>:remainder, :weightx=>0, :fill => :none)
    @hash_length.selected_item = 31

    add_gb(JLabel.new("Coverage Cutoff: "), :gridwidth => 1, :fill => :horizontal, :weightx=>0)
    add_gb(@cutoff_combo = JComboBox.new(["Auto","Custom"].to_java), :fill => :none)
    add_gb(@cutoff_tf = JTextField.new(), :gridwidth=>:remainder, :weightx=>1, :fill => :horizontal)

    add_gb(JLabel.new("Expected Coverage: "), :gridwidth => 1, :fill => :horizontal, :weightx=>0)
    add_gb(@cov_combo = JComboBox.new(["Auto","Custom"].to_java), :fill => :none)
    add_gb(@cov_tf = JTextField.new(), :gridwidth=>:remainder, :weightx=>1, :fill => :horizontal)
    @cutoff_combo.add_action_listener {|e| set_custom_vis(@cutoff_combo, @cutoff_tf) }
    @cov_combo.add_action_listener {|e| set_custom_vis(@cov_combo, @cov_tf) }
    set_custom_vis(@cutoff_combo, @cutoff_tf)
    set_custom_vis(@cov_combo, @cov_tf)
  end

  def set_custom_vis(combo, tf)
    tf.enabled = combo.selected_item != "Auto"
  end

  def select_file(fileField)
    fc=JFileChooser.new(fileField.text)
    fc.setFileSelectionMode(JFileChooser::DIRECTORIES_ONLY);
    if fc.showOpenDialog(fileField)==0
      fileField.set_text fc.getSelectedFile.getPath
    end
  end

  def out_directory
    @file1.text
  end

  def hash_length
    @hash_length.selected_item
  end

end

class VelvetInfo < JComponent
  def initialize(velvetg, velveth)
    super()
    @velvetg = velvetg
    @velveth = velveth

    setBorder(TitledBorder.new("Info"))
    setLayout BorderLayout.new
    add(box = Box.createHorizontalBox)
    if @velveth.found
      box.add(JLabel.new("Using Velvet version : "+ @velveth.version))
    else
      if @velveth.path
        msg="Unable to find velvet binaries in #{@velveth.path}"
      else
        msg="Unable to find velvet binaries in the system PATH"
      end
      box.add(JLabel.new(msg))
    end
    box.add(but = JButton.new("Select path to binary"))
    but.add_action_listener {|e| select_velvet_dir }
  end

  def select_velvet_dir
    fc=JFileChooser.new(@velveth.path)
    fc.setFileSelectionMode(JFileChooser::DIRECTORIES_ONLY);
    if fc.showOpenDialog(self)==0
      firePropertyChange("path", nil, fc.getSelectedFile.getPath)
    end
  end
end

class VelvetGUI < JFrame
  def initialize
    super "Velvet"

    System.setProperty("awt.useSystemAAFontSettings","on");
    System.setProperty("swing.aatext", "true");

    path = Settings.velvet_directory
    @velveth=VelvetBinary.new(path,"velveth")
    @velvetg=VelvetBinary.new(path,"velvetg")
    query_velvet
    create_components
  end

  def query_velvet
    # Make velveth options into "flags" which is how the binary expects them
    @velveth.std_options.each {|opt| opt.type='flag' if opt.type.nil? }

    @max_channels = @velveth.comp_options["CATEGORIES"].to_i || 1


    if @velveth.version != @velvetg.version
      JOptionPane.showMessageDialog(self, "Using different versions of velvetg/velveth", "version mismatch",
                                    JOptionPane::WARNING_MESSAGE)
    end
  end

  def update_velvet_path(path)
    Settings.velvet_directory = path
    @velveth=VelvetBinary.new(path,"velveth")
    @velvetg=VelvetBinary.new(path,"velvetg")
    content_pane.removeAll
    query_velvet
    create_components
  end

  def create_components
    setDefaultCloseOperation JFrame::EXIT_ON_CLOSE

    content_pane.add(vbox = Box.createVerticalBox)
    vbox.add(@info = VelvetInfo.new(@velveth, @velvetg))
    @info.add_property_change_listener("path") {|e| update_velvet_path(e.new_value) }

    vbox.add(hbox = Box.createHorizontalBox)
    hbox.add(@main_opts  = MainOptions.new)
    hbox.add JScrollPane.new(OptionList.new(@velveth.std_options + @velvetg.std_options))

    vbox.add(@filesSelector = FilesSelector.new)

    vbox.add(butBox = Box.createHorizontalBox)
    butBox.add(@addCh = JButton.new("Add channel"))
    butBox.add(@delCh = JButton.new("Remove channel"))
    butBox.add(analyzeBut = JButton.new("Analyze"))
    analyzeBut.add_action_listener { analyze }
    @addCh.add_action_listener { @filesSelector.add_channel ; toggle_add_del }
    @delCh.add_action_listener { @filesSelector.del_channel ; toggle_add_del }
    toggle_add_del

    vbox.add(@console = JTextField.new)

    #pack
    setSize 800, 600
  end

  def toggle_add_del
    @delCh.visible = @filesSelector.num_channels > 1
    @addCh.visible = @filesSelector.num_channels < @max_channels
    #pack
  end

  def analyze
    out_dir = @main_opts.out_directory
    if !File.directory?(out_dir)
      JOptionPane.showMessageDialog(self, "You must specify a valid output directory", "Invalid", JOptionPane::ERROR_MESSAGE)
      return
    end
    if !@filesSelector.valid_files
      JOptionPane.showMessageDialog(self, "Invalid sequence file(s)", "Invalid", JOptionPane::ERROR_MESSAGE)
      return
    end
    puts "RUN : velveth #{out_dir} #{@main_opts.hash_length} #{@filesSelector.to_command_line.join ' '} #{@velveth.std_options.to_command_line.join ' '}"
    puts "RUN : velvetg #{out_dir} #{@velvetg.std_options.to_command_line.join ' '}"
  end
end

