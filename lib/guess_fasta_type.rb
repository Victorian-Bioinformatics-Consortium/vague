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

require 'zlib'

class GuessFastaType
  def self.guess(file)
    begin
      Zlib::GzipReader.open(file) do |gz|
        ch = gz.readchar.chr
        return :fasta_gz if ch=='>'
        return :fastq_gz if ch=='@'
        return :unknown_gz
      end
    rescue Zlib::GzipFile::Error
    end
    File.open(file) do |f|
      ch = f.readchar.chr
      return :fasta if ch=='>'
      return :fastq if ch=='@'
      return :unknown
    end
  rescue
    return :unknown
  end
end
