require 'java'
require 'gridbag'
require 'velvet_binary'
require 'guess_fasta_type'
require 'runner'
require 'velvet_results'
require 'help_dialog'

include_class %w(java.awt.event.ActionListener
                 java.awt.BorderLayout
                 java.awt.GridBagLayout
                 java.awt.GridBagConstraints
                 java.awt.Dimension
                 java.awt.Color
                 java.awt.Font
                 java.lang.System
                 java.util.prefs.Preferences
                 javax.imageio.ImageIO
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
                 javax.swing.text.DefaultCaret
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
    setBorder(TitledBorder.new("Library #{num} Sequences"))
    initGridBag

    @typ = JComboBox.new(["single","paired end","mate pair"].to_java)
    @intLbl = JLabel.new("Interleaved sequence file: ")
    @interleaved = JComboBox.new(["interleaved","separate"].to_java)

    @files = []

    @fmt = JComboBox.new(["fasta","fastq","fasta.gz","fastq.gz"].to_java)

    @typ.add_action_listener {|e| update_boxes }
    @interleaved.add_action_listener {|e| update_boxes }

    add_file_widget
  end

  def layout_components
    remove_all
    gb_set_tip "Specify read type SINGLE, PAIRED END or MATE PAIR"
    add_gb(JLabel.new("Read type: "))
    add_gb(@typ, :gridwidth => :remainder, :fill => :none)
    gb_set_tip "Specify whether paired reads are interleaved in one file, or in separate files"
    add_gb(@intLbl)
    add_gb(@interleaved, :gridwidth => :remainder, :fill => :none)

    @files.each do |file|
      gb_set_tip "Specify sequence file(s)"
      add_gb(file[:file1Lbl])
      add_gb(file[:file1], :weightx => 1)
      add_gb(file[:file1Btn], :gridwidth => :remainder)

      add_gb(file[:file2Lbl])
      add_gb(file[:file2], :weightx => 1)
      add_gb(file[:file2Btn], :gridwidth => :remainder)
      add_gb(Box.createVerticalStrut(10), :gridwidth => :remainder)
    end

    gb_set_tip "Force file format to read files"
    add_gb(JLabel.new("Format: "))
    add_gb(@fmt, :fill => :none, :gridwidth => :remainder)

    gb_set_tip "Add another sequence file to this library"
    add_gb(addFilesBtn = JButton.new("Add another file"), :fill => :none, :gridwidth => :remainder)
    addFilesBtn.add_action_listener {|e| add_file_widget}
    #addFilesBtn.setFont(Font.new("sansserif",Font::PLAIN,10))

    update_boxes
  end

  def add_file_widget
    @files << new_file_widget
    layout_components
  end

  def new_file_widget
    file1Lbl = JLabel.new("Sequence file: ")
    file1 = JTextField.new
    file1Btn = JButton.new("...")

    file2Lbl = JLabel.new("Right Sequence file: ")
    file2 = JTextField.new
    file2Btn = JButton.new("...")

    file1Btn.add_action_listener {|e| select_file(file1) }
    file2Btn.add_action_listener {|e| select_file(file2) }

    { :file1 => file1, :file1Lbl => file1Lbl, :file1Btn => file1Btn,
      :file2 => file2, :file2Lbl => file2Lbl, :file2Btn => file2Btn}
  end

  def default_dir(fld)
    [fld.text, @files.first[:file1].text, @files.first[:file2].text].reject(&:empty?).first
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
    @files.each do |file|
      file[:file2Lbl].visible = file[:file2].visible = file[:file2Btn].visible = separate_files
      file[:file1Lbl].text = separate_files ? "Left Sequence file: " : "Sequence file: "
    end
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
      ret = ["-separate","-"+@fmt.selected_item, "-#{read_type}#{n}"]
      @files.each do |file|
        ret.concat [file[:file1].text, file[:file2].text]
      end
      ret
    else
      ret = ["-interleaved","-"+@fmt.selected_item, "-#{read_type}#{n}"]
      @files.each do |file|
        ret.concat [file[:file1].text]
      end
      ret
    end
  end

  def valid_files
    File.exists?(@files.first[:file1].text)
  end

  def set_file(file)
    @files.first[:file1].text = file
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
      add_gb(l = JLabel.new(opt.name))
      l.setToolTipText opt.desc

      add_gb(tf = create_editor(opt), :gridwidth=>:remainder, :weightx=>1, :fill => :none)
    end
  end

  def create_editor(opt)
    w=nil
    case opt.type
    when 'yes|no', 'flag'
      w = JCheckBox.new
      w.selected = opt.value == 'yes'
      w.setToolTipText opt.desc
      w.add_change_listener {|e| w.selected? ? opt.value='yes' : opt.value='no'}
    else
      w = JTextField.new(opt.value, 8)
      w.setToolTipText opt.desc
      w.get_document.add_document_listener {|e| opt.value = w.getText}
    end
    w
  end
end

class MainOptions < JComponent
  include GridBag
  def initialize(max_kmer, option_list)
    super()
    @max_kmer = max_kmer.to_i
    @max_kmer = 31 if @max_kmer < 5
    @default_kmer = 31
    @option_list = option_list

    initGridBag
    setBorder(TitledBorder.new("Options"))

    gb_set_tip 'Set output directory to store results from velvet'
    add_gb(JLabel.new("Output Directory: "))
    add_gb(@file1 = JTextField.new, :weightx => 1, :gridwidth=>2)
    add_gb(file1Btn = JButton.new("..."), :gridwidth => :remainder)
    file1Btn.add_action_listener {|e| select_file(@file1) }

    add_gb(JLabel.new("K-mer size: "))
    add_gb(@hash_length = JComboBox.new((5..@max_kmer).step(2).to_a.to_java), :gridwidth=>:remainder, :weightx=>0, :fill => :none)
    @hash_length.selected_item = @default_kmer

    gb_set_tip get_tip('cov_cutoff')
    add_gb(JLabel.new("Coverage Cutoff: "))
    add_gb(@cutoff_combo = JComboBox.new(["Auto","Custom","Don't use"].to_java), :fill => :none)
    add_gb(@cutoff_tf = JTextField.new(5), :gridwidth => :remainder, :fill => :none)

    gb_set_tip get_tip('exp_cov')
    add_gb(JLabel.new("Expected Coverage: "))
    add_gb(@estcov_combo = JComboBox.new(["Auto","Custom", "Don't use"].to_java), :fill => :none)
    add_gb(@estcov_tf = JTextField.new(5), :gridwidth=>:remainder, :fill => :none)
    @cutoff_combo.add_action_listener {|e| set_custom_vis(@cutoff_combo, @cutoff_tf) }
    @estcov_combo.add_action_listener {|e| set_custom_vis(@estcov_combo, @estcov_tf) }
    set_custom_vis(@cutoff_combo, @cutoff_tf)
    set_custom_vis(@estcov_combo, @estcov_tf)

    gb_set_tip get_tip('min_contig_lgth')
    add_gb(JLabel.new("Min. contig length: "))
    add_gb(@min_contig_len_combo = JComboBox.new(["Auto","Custom"].to_java), :fill => :none)
    add_gb(@min_contig_len_tf = JTextField.new(5), :gridwidth=>:remainder, :fill => :none)
    @min_contig_len_combo.add_action_listener {|e| set_custom_vis(@min_contig_len_combo, @min_contig_len_tf) }
    set_custom_vis(@min_contig_len_combo, @min_contig_len_tf)
    @min_contig_len_combo.selected_item = 'Custom'
    @min_contig_len_tf.text = 500.to_s
    @hash_length.add_action_listener {|e| update_auto_contig_length }
    update_auto_contig_length
  end

  # Use text from velvet.  Override here if we want to provide better help text for the main options
  def get_tip(fld)
    case fld
    when 'min_contig_lgth'
      opt = @option_list.get('min_contig_lgth')
      opt ? opt.desc.sub(/\(.*/,'') : nil
    else
      opt = @option_list.get(fld)
      opt ? opt.desc : nil
    end
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

  def min_contig_len_option
    if @min_contig_len_combo.selected_item=="Custom"
      ["-min_contig_lgth", @min_contig_len_tf.text]
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
    [out_directory] + cutoff_option + estcov_option + min_contig_len_option
  end
end

class VelvetInfo < JComponent
  include GridBag
  def initialize(velvetg, velveth)
    super()
    @velvetg = velvetg
    @velveth = velveth

    setBorder(TitledBorder.new("Info"))
    initGridBag

    found_msg = if @velveth.found then "Using" else "Unable to find" end
    @loc_lbl = JLabel.new(if @velveth.path
                            "#{found_msg} velvet in : #{@velveth.path}"
                          else
                            "#{found_msg} velvet in system PATH"
                          end
                          )
    if !@velveth.found
      @loc_lbl.foreground = Color::red
    end
    add_gb(@loc_lbl, :gridwidth => 2, :weightx => 1)

    add_gb(but = JButton.new("Set"))
    but.add_action_listener {|e| select_velvet_dir }
    add_gb(but2 = JButton.new("Reset"))
    but2.add_action_listener {|e| firePropertyChange("path", nil, "") }
    but2.visible = !@velveth.path.nil?
    add_gb(JLabel.new, :gridwidth => :remainder)     # End of row filler


    if @velveth.found
      add_gb(label("Velvet version : "))
      add_gb(value(@velveth.version), :gridwidth => :remainder, :weightx => 1)

      add_gb(label("Max k-mer size : "))
      add_gb(value(@velveth.max_kmer.to_s), :gridwidth => :remainder, :weightx =>1)
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

    path = Settings.velvet_directory
    update_velvet_binary(path)

    check_velvet_exists

    # HACK for testing!
    if ARGV.length > 0
      @main_opts.instance_variable_get('@file1').send('text=', ARGV[0])
      @filesSelector.instance_variable_get('@selectors').first.set_file(ARGV[1])
    end

    setLocationRelativeTo(nil)
  end

  def query_velvet
    # Make velveth options into "flags" which is how the binary expects them
    @velveth.std_options.each {|opt| opt.type='flag' if opt.type.nil? }

    @max_channels = @velveth.max_categories || 1


    if @velveth.version != @velvetg.version
      JOptionPane.showMessageDialog(self, "Using different versions of velvetg/velveth", "version mismatch",
                                    JOptionPane::WARNING_MESSAGE)
    end
  end

  def check_velvet_exists
    if !@velveth.found
      JOptionPane.showMessageDialog(self, "Unable to find velvet binaries.  Please specify the path to velvet",
                                    "velvet missing", JOptionPane::WARNING_MESSAGE)
      @info.select_velvet_dir
    end
  end

  def update_velvet_binary(path)
    @velveth=VelvetBinary.new(path,"velveth")
    @velvetg=VelvetBinary.new(path,"velvetg")

    # Expand command line params as necessary
    @velvetg.std_options.expand_opts!("ins_length2", "2", (1..@velveth.max_categories).to_a)
    @velvetg.std_options.expand_opts!("ins_length*_sd", "*", (1..@velveth.max_categories).to_a + ['_long'])
    @velvetg.std_options.expand_opts!("shortMatePaired*", "*", (1..@velveth.max_categories).to_a)

    content_pane.removeAll
    query_velvet
    create_components
  end

  def set_velvet_path(path)
    Settings.velvet_directory = path
    update_velvet_binary(path)
  end

  def create_components
    setDefaultCloseOperation JFrame::EXIT_ON_CLOSE

    content_pane.add(@tabs = JTabbedPane.new)

    @tabs.addTab("Setup", nil, create_main_tab, "Setup the main options")
    @tabs.addTab("Advanced", nil, create_advanced_tab, "Configure advanced options for velvet")
    @tabs.addTab("Log", nil, JScrollPane.new(@console = JTextArea.new), "Log output from running velvet process")
    @tabs.addTab("Results", nil, @output = VelvetResultsComp.new, "Summary of results after running velvet")
    @console.font = Font.new("Monospaced", Font::PLAIN, 12)
    @console.editable = false
    @console.getCaret().setUpdatePolicy(DefaultCaret::ALWAYS_UPDATE)

    #pack
    setSize 500, 600
  end

  def create_advanced_tab
    vbox = Box.createVerticalBox
    vbox.add(@info = VelvetInfo.new(@velveth, @velvetg))
    @info.add_property_change_listener("path") {|e| set_velvet_path(e.new_value) }

    hide_options = %w(cov_cutoff min_contig_lgth ins_length)
    defaults = {'clean' => 'yes', 'scaffolding' => 'yes', 'create_binary' => 'yes'}
    opts = @velveth.std_options + @velvetg.std_options
    opts.hide!(hide_options)
    opts.set_defaults!(defaults)

    vbox.add(JScrollPane.new(OptionList.new(opts)))
    vbox
  end

  def show_about
    str = <<-STR;
      <html>
        <h2>Vague - Velvet Assembler Graphical User Environment</h2>
        Written by <b>David R. Powell</b> (<code>david.powell@monash.edu</code>)
        <i>Victorian Bioinformatics Consortium</i>
    STR
    str.gsub!(/^\s+/,'')
    str.gsub!(/\n/,'<br>')
    JOptionPane.showMessageDialog(self, str,
                                  "Vague about", JOptionPane::INFORMATION_MESSAGE)
  end

  def show_help
    HelpDialog.new(self)
  end

  def create_main_tab
    vbox = Box.createVerticalBox

    vbox.add(hbox = Box.createHorizontalBox)
    hbox.add Box.createHorizontalGlue
    img = java_class.resource("/vague/images/vague.png") || java_class.resource("/images/vague.png")
    hbox.add(logo = JLabel.new(ImageIcon.new(img)))
    hbox.add Box.createHorizontalGlue
    hbox.add(helpBox = Box.createVerticalBox)
    helpBox.add(aboutBut = JButton.new("About"))
    helpBox.add(helpBut = JButton.new("Help"))
    aboutBut.setFont(Font.new("serif",Font::PLAIN,10))
    helpBut.setFont(Font.new("serif",Font::PLAIN,10))
    aboutBut.add_action_listener {|e| show_about }
    helpBut.add_action_listener {|e| show_help }

    vbox.add(@main_opts  = MainOptions.new(@velveth.max_kmer, @velveth.std_options + @velvetg.std_options))

    vbox.add(sc=JScrollPane.new(@filesSelector = FilesSelector.new))
    sc.getViewport.setOpaque(false)
    sc.setOpaque(false)
    sc.border = nil

    vbox.add(butBox = Box.createHorizontalBox)
    butBox.add(@addCh = JButton.new("Add library"))
    butBox.add(@delCh = JButton.new("Remove library"))
    butBox.add(Box.createHorizontalGlue)
    butBox.add(@analyzeBut = JButton.new("Analyze"))
    @analyzeBut.add_action_listener {|e| analyze }
    @addCh.add_action_listener {|e| @filesSelector.add_channel ; toggle_add_del }
    @delCh.add_action_listener {|e| @filesSelector.del_channel ; toggle_add_del }
    toggle_add_del

    @addCh.setToolTipText "Add another sequence library"
    @delCh.setToolTipText "Remove last sequence library"
    @analyzeBut.setToolTipText "Run velvet assembler"

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

  def started
    @analyzeBut.enabled = false
  end

  def finished
    @analyzeBut.enabled = true
  end

  def velveth_command_line
    [@velveth.exe] +
      @main_opts.velveth_command_line +
      @filesSelector.to_command_line +
      @velveth.std_options.to_command_line
  end

  def velvetg_command_line
    [@velvetg.exe] +
      @main_opts.velvetg_command_line +
      @velvetg.std_options.to_command_line
  end

  def show_command_line
    @console.append "Unable to find velvet.  Command line that would be used:\n"
    @console.append ">>> RUN : #{velveth_command_line.join ' '}\n"
    @console.append ">>> RUN : #{velvetg_command_line.join ' '}\n"
  end

  def run_velveth
    if !@velveth.found
      show_command_line
      return
    end

    @console.text = ""
    started
    @console.append ">>> RUNNING : #{velveth_command_line.join ' '}\n"
    @runner = Runner.new(velveth_command_line)
    @runner.add_property_change_listener('stdout') {|e| @console.append e.new_value}
    @runner.add_property_change_listener('done') do |e|
      if e.new_value == 0
        @console.append ">>> velveth successful\n"
        run_velvetg
      else
        @console.append ">>> velveth failed\n"
        finished
      end
    end
    @runner.add_property_change_listener('error') {|e| @console.append "ERROR" ; finished }
    @runner.start
  end

  def run_velvetg
    @console.append ">>> RUNNING : #{velvetg_command_line.join ' '}\n"
    @runner = Runner.new(velvetg_command_line)
    @runner.add_property_change_listener('stdout') {|e| @console.append e.new_value}
    @runner.add_property_change_listener('done') do |e|
      if e.new_value == 0
        @console.append ">>> velvetg successful\n"
        @tabs.selected_index = 3
        @output.update_results(File.join(@main_opts.out_directory,"contigs.fa"), @console.text)
      else
        @console.append ">>> velvetg failed\n"
      end
      finished
    end
    @runner.add_property_change_listener('error') {|e| @console.append "ERROR" ; finished}
    @runner.start
  end
end


