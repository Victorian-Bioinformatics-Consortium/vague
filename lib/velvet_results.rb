
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

    add(@splitPane = JSplitPane.new(1, JScrollPane.new(@contigs), JScrollPane.new(@sequence)))
    update_results(nil)
  end

  def update_results(file)
    @results = VelvetResults.new(file)
    @contigs.list_data = @results.contig_names.to_java
    @contigs.selected_index = 0
    @splitPane.divider_location=0.2
  end
end
