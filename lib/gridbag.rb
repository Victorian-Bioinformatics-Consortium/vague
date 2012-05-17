module GridBag
  def initGridBag
    setLayout(@gridbag = GridBagLayout.new)
    @constraints = GridBagConstraints.new
  end

  def add_gb(w, params={})
    params.each do |k,v|
      v = GridBagConstraints::HORIZONTAL if v==:horizontal
      v = GridBagConstraints::NONE if v==:none
      v = GridBagConstraints::REMAINDER if v==:remainder
      v = GridBagConstraints::WEST if v==:west
      v = GridBagConstraints::NORTHWEST if v==:northwest
      @constraints.send("#{k}=",v)
    end
    @gridbag.setConstraints(w, @constraints)
    add w
  end
end
