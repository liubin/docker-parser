require 'ffi/aspell'

# cache to save word => check result
# $cache = Hash.new

$speller = nil

class SourceLine

  attr_accessor :words, :path, :line, :line_number, :invalid_words, :colorize_line
  # path is fullpath(dir + filename)
  def initialize(path, line_number, line)
    @path = path
    @line_number = line_number
    @line = line
    @colorize_line = @line
  end

  def parse
    @words = @line.split
    @invalid_words = []
    @words.each do |word|
      w = word.gsub(/([\.,*\'\";:\(\)])*/,'')
      if !$speller.correct? w
        @invalid_words.push w
        @colorize_line = @colorize_line.sub(word, "\e[31m#{w}\e[0m")
      end

    end
  end

end



# split comments in a file to array
def split_file file
  lines = []
  File.foreach(file).with_index do |line, line_num|
    line_content = line.strip
    if line_content.start_with? "//"
      line_content.sub!('//', '')
      sl = SourceLine.new(file, line_num + 1, line_content)
      sl.parse
      lines.push sl
    end
  end
  lines
end

def spell_check_file file
  puts "------------- #{file}"

  lines = split_file file
  lines.each do |sl|
    if sl.invalid_words.count >0
      puts "#{sl.line_number} #{sl.colorize_line}"
    end
  end

end

# parse one directory
def spell_check_dir dir

  Dir.foreach(dir) do |f|
    next if f == '.' || f == '..'
    file = "#{dir}/#{f}"
    if File.directory? file
      spell_check_dir file
    elsif File.file? file
      spell_check_file file if f.end_with? ".go"
    end
  end # foreach dir

end


def main(path)
  $speller = FFI::Aspell::Speller.new('en_US')
  spell_check_dir path
  $speller.close
end



$root = ENV['SRC']

if $root.nil?
  puts "hehe"
else
  main $root
end

