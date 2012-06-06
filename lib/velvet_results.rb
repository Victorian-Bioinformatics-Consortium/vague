
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
        name = line[1..-1]
        current = {:name => name, :seq => String.new, :len => 0}
        @contigs[name] = current
      else
        raise "Bad FASTA file" if !current
        current[:seq].concat(line)
        current[:len] += line.chomp.length
      end
    end
  end

  def contig_names
    @contigs.keys
  end

  def contig(name)
    @contigs[name][:name] + @contigs[name][:seq]
  end

  def min_contig
    @contigs.map {|k,v| v[:len]}.min
  end

  def num_contigs
    @contigs.size
  end
end

class ResultStats < JComponent
  include GridBag

  def initialize
    super
    initGridBag
    setBorder(TitledBorder.new("Stats"))
  end

  def update_results(log_output, velvet_results)
    remove_all
    md = log_output.match(/n50 of (\d+), max (\d+), total (\d+)/)

    if md
      add_gb label("Total BP ")
      add_gb value(md[3]), :gridwidth => :remainder, :weightx =>1
      add_gb label("Max contig ")
      add_gb value(md[2]), :gridwidth => :remainder
      add_gb label("Min contig ")
      add_gb value(velvet_results.min_contig.to_s), :gridwidth => :remainder
      add_gb label("N50 ")
      add_gb value(md[1]), :gridwidth => :remainder
    end
    add_gb label("Num contigs ")
    add_gb value(velvet_results.num_contigs.to_s), :gridwidth => :remainder

    setMaximumSize Dimension.new(getMaximumSize.width, getPreferredSize.height)
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

    @contigs.addListSelectionListener {|e| select_contig }

    vbox = Box.createVerticalBox
    vbox.add(@result_stats = ResultStats.new)
    vbox.add(JScrollPane.new(@contigs))

    add(@splitPane = JSplitPane.new(1, vbox, JScrollPane.new(@sequence)))
    update_results(nil, nil)
  end

  def select_contig
    return if !@contigs.selected_value
    @sequence.text = @results.contig(@contigs.selected_value)
    @sequence.setCaretPosition(0)
  end

  def update_results(file, log_output)
    @results = VelvetResults.new(file)
    @contigs.list_data = @results.contig_names.to_java
    @result_stats.update_results(log_output, @results) if log_output
    @contigs.selected_index = 0

    @splitPane.divider_location=0.4
    revalidate
  end
end
