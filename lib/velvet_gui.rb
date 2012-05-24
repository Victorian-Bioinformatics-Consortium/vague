require 'java'
require 'gridbag'
require 'velvet_binary'
require 'guess_fasta_type'
require 'runner'

include_class %w(java.awt.event.ActionListener
                 java.awt.BorderLayout
                 java.awt.GridBagLayout
                 java.awt.GridBagConstraints
                 java.awt.Dimension
                 java.awt.Color
                 java.lang.System
                 java.util.prefs.Preferences
                 javax.swing.JOptionPane
                 javax.swing.SwingUtilities
                 javax.swing.JButton
                 javax.swing.JFrame
                 javax.swing.JLabel
                 javax.swing.JTextField
                 javax.swing.JTextArea
                 javax.swing.JComponent
                 javax.swing.JComboBox
                 javax.swing.JCheckBox
                 javax.swing.Box
                 javax.swing.BoxLayout
                 javax.swing.JFileChooser
                 javax.swing.JButton
                 javax.swing.ImageIcon
                 javax.swing.JScrollPane
                 javax.swing.JTabbedPane
                 javax.swing.border.TitledBorder
                )

class Settings
  def self.prefs
    @prefs ||= Preferences.userRoot.node('vbc/vague')
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
    when 'single'
      'short'
    when 'paired end'
      'shortPaired'
    else
      'longPaired'
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
    when 'yes|no', 'flag'
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
  def initialize(max_kmer)
    super()
    @max_kmer = max_kmer.to_i || 31
    @default_kmer = 31

    initGridBag
    setBorder(TitledBorder.new("Main Options"))

    add_gb(JLabel.new("Output Directory: "), :gridwidth => 1, :fill => :horizontal, :anchor => :northwest, :weightx=>0)
    add_gb(@file1 = JTextField.new, :weightx => 1, :gridwidth=>2)
    add_gb(file1Btn = JButton.new("..."), :gridwidth => :remainder, :weightx => 0)
    file1Btn.add_action_listener {|e| select_file(@file1) }

    add_gb(JLabel.new("Hash Length: "), :gridwidth => 1, :fill => :horizontal, :weightx=>0)
    add_gb(@hash_length = JComboBox.new((5..@max_kmer).step(2).to_a.to_java), :gridwidth=>:remainder, :weightx=>0, :fill => :none)
    @hash_length.selected_item = @default_kmer

    add_gb(JLabel.new("Coverage Cutoff: "), :gridwidth => 1, :fill => :horizontal, :weightx=>0)
    add_gb(@cutoff_combo = JComboBox.new(["Auto","Custom","Don't use"].to_java), :fill => :none)
    add_gb(@cutoff_tf = JTextField.new(), :gridwidth=>:remainder, :weightx=>1, :fill => :horizontal)

    add_gb(JLabel.new("Expected Coverage: "), :gridwidth => 1, :fill => :horizontal, :weightx=>0)
    add_gb(@estcov_combo = JComboBox.new(["Auto","Custom", "Don't use"].to_java), :fill => :none)
    add_gb(@estcov_tf = JTextField.new(), :gridwidth=>:remainder, :weightx=>1, :fill => :horizontal)
    @cutoff_combo.add_action_listener {|e| set_custom_vis(@cutoff_combo, @cutoff_tf) }
    @estcov_combo.add_action_listener {|e| set_custom_vis(@estcov_combo, @estcov_tf) }
    set_custom_vis(@cutoff_combo, @cutoff_tf)
    set_custom_vis(@estcov_combo, @estcov_tf)

    add_gb(JLabel.new("Min. contig length: "), :gridwidth => 1, :fill => :horizontal, :weightx=>0)
    add_gb(@min_contig_len_combo = JComboBox.new(["Auto","Custom"].to_java), :fill => :none)
    add_gb(@min_contig_len_tf = JTextField.new(), :gridwidth=>:remainder, :weightx=>1, :fill => :horizontal)
    @min_contig_len_combo.add_action_listener {|e| set_custom_vis(@min_contig_len_combo, @min_contig_len_tf) }
    set_custom_vis(@min_contig_len_combo, @min_contig_len_tf)
    @min_contig_len_combo.selected_item = 'Custom'
    @min_contig_len_tf.text = 500.to_s
    @hash_length.add_action_listener {|e| update_auto_contig_length }
    update_auto_contig_length

    add_gb(JLabel.new("Read Tracking: "), :gridwidth => 1, :fill => :horizontal, :weightx=>0)
    add_gb(@read_tracking = JCheckBox.new(), :gridwidth=>:remainder, :fill => :none)

    add_gb(JLabel.new("Scaffolding: "), :gridwidth => 1, :fill => :horizontal, :weightx=>0)
    add_gb(@scaffolding = JCheckBox.new(), :gridwidth=>:remainder, :fill => :none)
    @scaffolding.selected = true
  end

  def set_custom_vis(combo, tf)
    tf.enabled = combo.selected_item != "Auto"
  end

  def select_file(fileField)
    fc=JFileChooser.new(fileField.text)
    fc.setFileSelectionMode(JFileChooser::DIRECTORIES_ONLY)
    if fc.showOpenDialog(fileField)==0
      fileField.set_text fc.getSelectedFile.getPath
    end
  end

  def update_auto_contig_length
    if @min_contig_len_combo.selected_item == 'Auto'
      @min_contig_len_tf.text = (2 * @hash_length.selected_item).to_s
    end
  end

  def cutoff_option
    case @cutoff_combo.selected_item
    when 'Auto'
      ['-cov_cutoff', 'auto']
    when 'Custom'
      ['-cov_cutoff', @cutoff_tf.text]
    else []
    end
  end

  def estcov_option
    case @estcov_combo.selected_item
    when 'Auto'
      ['-exp_cov', 'auto']
    when 'Custom'
      ['-exp_cov', @estcov_tf.text]
    else []
    end
  end

  def read_tracking_option
    if @read_tracking.selected?
      ["-read_trkg", "yes"]
    else
      []
    end
  end

  def min_contig_len_option
    if @min_contig_len_combo.selected_item=="Custom"
      ["-min_contig_lgth", @min_contig_len_tf.text]
    else
      []
    end
  end

  def scaffolding_option
    if @scaffolding.selected?
      ["-scaffolding", "yes"]
    else
      []
    end
  end

  def out_directory
    @file1.text
  end

  def velveth_command_line
    [out_directory, @hash_length.selected_item.to_s]
  end

  def velvetg_command_line
    [out_directory] + cutoff_option + estcov_option + read_tracking_option + min_contig_len_option + scaffolding_option
  end
end

class VelvetInfo < JComponent
  def initialize(velvetg, velveth)
    super()
    @velvetg = velvetg
    @velveth = velveth

    setBorder(TitledBorder.new("Info"))
    setLayout BorderLayout.new
    add(vbox = Box.createVerticalBox)

    vbox.add(hbox = Box.createHorizontalBox)
    hbox.alignment_x = Box::LEFT_ALIGNMENT

    found_msg = if @velveth.path then "Using" else "Unable to find" end
    hbox.add(@loc_lbl = JLabel.new(if @velveth.path
                                     "#{found_msg} velvet in : #{@velveth.path}"
                                   else
                                     "#{found_msg} velvet in system PATH"
                                   end
                                   ))

    hbox.add(Box.createGlue)
    hbox.add(but = JButton.new("Set"))
    but.add_action_listener {|e| select_velvet_dir }
    if @velveth.path
      hbox.add(but2 = JButton.new("Reset"))
      but2.add_action_listener {|e| firePropertyChange("path", nil, "") }
    else
      @loc_lbl.foreground = Color::red
    end

    if @velveth.found
      vbox.add(lbl=JLabel.new("Velvet version : "+ @velveth.version))
      lbl.alignment_x = Box::LEFT_ALIGNMENT
    end

    setMaximumSize Dimension.new(getMaximumSize.width, getPreferredSize.height)
  end

  def select_velvet_dir
    fc=JFileChooser.new(@velveth.path)
    fc.setFileSelectionMode(JFileChooser::DIRECTORIES_ONLY)
    if fc.showOpenDialog(self)==0
      firePropertyChange("path", nil, fc.getSelectedFile.getPath)
    end
  end
end

class VelvetGUI < JFrame
  def initialize
    super "Velvet"

    System.setProperty("awt.useSystemAAFontSettings","on")
    System.setProperty("swing.aatext", "true")

    path = Settings.velvet_directory
    @velveth=VelvetBinary.new(path,"velveth")
    @velvetg=VelvetBinary.new(path,"velvetg")
    query_velvet
    create_components

    # HACK for testing!
    if ARGV.length > 0
      @main_opts.instance_variable_get('@file1').send('text=', ARGV[0])
      @filesSelector.instance_variable_get('@selectors').first.instance_variable_get('@file1').send('text=', ARGV[1])
    end
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

    content_pane.add(@tabs = JTabbedPane.new)

    @tabs.addTab("Main", create_main_tab)
    @tabs.addTab("Advanced", create_advanced_tab)
    @tabs.addTab("Log Output",JScrollPane.new(@console = JTextArea.new))
    @console.editable = false

    #pack
    setSize 500, 600
  end

  def create_advanced_tab
    hide_options = %w(cov_cutoff read_trkg min_contig_lgth scaffolding)
    opts = @velveth.std_options + @velvetg.std_options
    opts = opts.reject {|o| hide_options.include?(o.name) }
    JScrollPane.new(OptionList.new(opts))
  end

  def create_main_tab
    vbox = Box.createVerticalBox
    vbox.add(@info = VelvetInfo.new(@velveth, @velvetg))
    @info.add_property_change_listener("path") {|e| update_velvet_path(e.new_value) }

    vbox.add(hbox = Box.createHorizontalBox)
    hbox.add(@main_opts  = MainOptions.new(@velveth.comp_options['MAXKMERLENGTH']))

    vbox.add(@filesSelector = FilesSelector.new)

    vbox.add(butBox = Box.createHorizontalBox)
    butBox.add(@addCh = JButton.new("Add channel"))
    butBox.add(@delCh = JButton.new("Remove channel"))
    butBox.add(analyzeBut = JButton.new("Analyze"))
    analyzeBut.add_action_listener {|e| analyze }
    @addCh.add_action_listener {|e| @filesSelector.add_channel ; toggle_add_del }
    @delCh.add_action_listener {|e| @filesSelector.del_channel ; toggle_add_del }
    toggle_add_del

    vbox
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

    @tabs.selected_index = 2

    run_velveth
  end

  def run_velveth
    velveth_command_line = [@velveth.exe] +
                            @main_opts.velveth_command_line +
                            @filesSelector.to_command_line +
                            @velveth.std_options.to_command_line
    @console.append ">>> RUNNING : #{velveth_command_line.join ' '}\n"
    @runner = Runner.new(velveth_command_line)
    @runner.add_property_change_listener('stdout') {|e| @console.append e.new_value}
    @runner.add_property_change_listener('done') do |e|
      if e.new_value == 0
        @console.append ">>> velveth successful\n"
        run_velvetg
      else
        @console.append ">>> velveth failed\n"
      end
    end
    @runner.add_property_change_listener('error') {|e| @console.append "ERROR"}
    @runner.start
  end

  def run_velvetg
    velvetg_command_line = [@velvetg.exe] +
                            @main_opts.velvetg_command_line +
                            @velvetg.std_options.to_command_line
    @console.append ">>> RUNNING : #{velvetg_command_line.join ' '}\n"
    @runner = Runner.new(velvetg_command_line)
    @runner.add_property_change_listener('stdout') {|e| @console.append e.new_value}
    @runner.add_property_change_listener('done') do |e|
      if e.new_value == 0
        @console.append ">>> velvetg successful\n"
      else
        @console.append ">>> velvetg failed\n"
      end
    end
    @runner.add_property_change_listener('error') {|e| @console.append "ERROR"}
    @runner.start
  end
end


