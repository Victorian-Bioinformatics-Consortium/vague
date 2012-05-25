module GridBag
  def initGridBag
    setLayout(@gridbag = GridBagLayout.new)
  end

  def add_gb(w, params={})
    def_params = { :gridwidth => 1, :anchor => :northwest, :fill => :horizontal, :weightx => 0 }

    constraints = GridBagConstraints.new
    def_params.merge(params).each do |k,v|
      v = GridBagConstraints::HORIZONTAL if v==:horizontal
      v = GridBagConstraints::NONE if v==:none
      v = GridBagConstraints::REMAINDER if v==:remainder
      v = GridBagConstraints::WEST if v==:west
      v = GridBagConstraints::NORTHWEST if v==:northwest
      constraints.send("#{k}=",v)
    end
    @gridbag.setConstraints(w, constraints)
    add w
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
