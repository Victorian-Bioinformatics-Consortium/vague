
include_class %w(javax.swing.JComponent
                 javax.swing.JList
                 javax.swing.ListSelectionModel
                 javax.swing.JSplitPane
                 java.awt.BorderLayout
                )

class VelvetResults
  def initialize(file=nil)
    @contigs = {}
    return if !file

    current = nil
    File.open(file).each do |line|
      if line.start_with?('>')
        @contigs[line[1..-1]] = current = String.new(line)
      else
        raise "Bad FASTA file" if !current
        current.concat(line)
      end
    end
  end

  def contig_names
    @contigs.keys
  end

  def contig(name)
    @contigs[name]
  end
end

class ResultStats < JComponent
  include GridBag

  def initialize
    super
    initGridBag
    setBorder(TitledBorder.new("Stats"))
  end

  def update_results(log_output)
    remove_all
    md = log_output.match(/n50 of (\d+), max (\d+), total (\d+)/)
    return if !md

    add_gb label("Total BP ")
    add_gb value(md[3]), :gridwidth => :remainder, :weightx =>1
    add_gb label("Max contig ")
    add_gb value(md[2]), :gridwidth => :remainder
    add_gb label("N50 ")
    add_gb value(md[1]), :gridwidth => :remainder

    setMaximumSize Dimension.new(getMaximumSize.width, getPreferredSize.height)
  end

  def label(msg)
    lbl = JLabel.new(msg)
    lbl.font = Font.new(lbl.font.name,Font::BOLD,lbl.font.size)
    lbl
  end

  def value(msg)
    JLabel.new(msg)
  end
end

class VelvetResultsComp < JComponent
  def initialize
    super
    setLayout BorderLayout.new
    @contigs = JList.new
    @contigs.setSelectionMode(ListSelectionModel::SINGLE_SELECTION)
    @contigs.font = Font.new("Monospaced", Font::PLAIN, 12)

    @sequence = JTextArea.new
    @sequence.editable = false
    @sequence.font = Font.new("Monospaced", Font::PLAIN, 12)

    @contigs.addListSelectionListener {|e| @sequence.text = @results.contig(@contigs.selected_value) }

    vbox = Box.createVerticalBox
    vbox.add(@result_stats = ResultStats.new)
    vbox.add(JScrollPane.new(@contigs))

    add(@splitPane = JSplitPane.new(1, vbox, JScrollPane.new(@sequence)))
    update_results(nil, nil)
  end

  def update_results(file, log_output)
    @results = VelvetResults.new(file)
    @contigs.list_data = @results.contig_names.to_java
    @contigs.selected_index = 0
    @result_stats.update_results(log_output) if log_output

    @splitPane.divider_location=0.4
    revalidate
  end
end
