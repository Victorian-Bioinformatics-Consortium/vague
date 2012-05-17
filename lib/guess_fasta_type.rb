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
