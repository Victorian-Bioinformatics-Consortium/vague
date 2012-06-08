# This file is part of : Vague - a GUI frontend for "velvet" a genomic sequence assembler
# Copyright (C) 2012 David R. Powell
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

module GridBag
  def initGridBag
    setLayout(@gridbag = GridBagLayout.new)
    @current_tip = nil
  end

  def gb_set_tip(tip)
    @current_tip = tip
  end

  def add_gb(w, params={})
    def_params = { :gridwidth => 1, :fill => :horizontal, :weightx => 0, :anchor => GridBagConstraints::BASELINE_LEADING }

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
    w.setToolTipText(@current_tip) if @current_tip
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
