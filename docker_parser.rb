require 'ffi/aspell'

# cache to save word => check result
# $cache = Hash.new

$speller = nil

$white_list = ['docker', 'dockerfile', 'eof', 'systemd', 'namespace', 'init',
  'lxc', 'dns', 'dosnt', 'dont', 'busybox', 'json', 'config', 'libcontainer',
  'api', 'cpu', 'stdin', 'stdout', 'stderr', 'fixme', 'tls', 'lookup', 'bash',
  'tcp', 'ip', 'ipv4', 'ipv6', 'tty', 'localhost', 'dir', 'linux', 'struct',
  'tmp', 'cgroup', 'cgroups', 'aufs', 'http', 'filesystem', 'goroutine', 'unix',
  'cgi', 'go', 'fd', 'url', 'uri', 'sqlite', 'docker', 'runtime', 'ipc', 'sudo',
  'pid', 'sigterm', 'sigkill', 'redhat', 'https', 'openstack', 'iptables', 'centos',
  'ubuntu', 'epel', 'nginx', 'apache', 'apache2', 'sshd', 'boot2docker', 'vm', 'osx',
  'cli', 'btrfs', 'virtualbox']

def is_white?(str)
  return true if $white_list.include? str.downcase
  false
end

class SourceLine

  attr_accessor :words, :path, :line, :line_number, :invalid_words, :colorize_line
  # path is fullpath(dir + filename)
  def initialize(path, line_number, line)
    @path = path
    @line_number = line_number
    @line = line
    @colorize_line = @line.gsub('<', '&lt;')
    @colorize_line = @colorize_line.gsub('>', '&gt;')
  end

  # return true has incorrect words
  def parse
    @words = @line.split
  
    @invalid_words = []
    @words.each do |word|
      w = word.gsub(/([\+\.,*\'\";:\(\)`\[\]?!#])*/,'')
      w = w.gsub('&lt;', '')
      w = w.gsub('&gt;', '')
      next if w == ''
      next if w.to_i.to_s == w # ignore integers
      next if is_white?(w)

      # process < and >
      if !(word.include? '<' or word.include? '>')
        next if w.start_with? "http"
        next if w.include? '-'
        next if w.downcase.start_with? 'todo'
      end


      if !$speller.correct? w
        @invalid_words.push w
        if ENV['HTML']
          @colorize_line = @colorize_line.gsub(word, "<span style='color: red;font-weight: bold;'>#{word}</span>")
        else
          @colorize_line = @colorize_line.gsub(word, "\e[31m#{word}\e[0m")
        end
      end # speller.correct

    end # end for each word
    @invalid_words.count !=0
  end

end


class SourceFile
  attr_accessor :path, :lines, :has_error
  # path is fullpath(dir + filename)
  def initialize(path, lines, has_error)
    @path = path
    @lines = lines
    @has_error = has_error
  end

end

# split comments in a file to array
def split_file file
  lines = []
  has_error = false
  File.foreach(file).with_index do |line, line_num|
    line_content = line.strip
    if line_content.start_with? "//" or $ext == ".md"
      line_content.sub!('//', '')
      sl = SourceLine.new(file, line_num + 1, line_content)
      has_error = sl.parse
      lines.push sl
    end
  end
  lines
  SourceFile.new(file, lines, has_error)
end

def spell_check_file file

  fo = split_file file
  return if !fo.has_error

  href = "https://github.com/docker/#{$repo}/blob/master#{file.sub($root + "/" + $repo, '')}"

  if ENV['HTML']
    puts "<a href='#{href}' target='_blank'>#{href}</a><br>"
  else
    puts "------------- #{file}"
  end

  fo.lines.each do |sl|
    if sl.invalid_words.count >0
      if ENV['HTML']
        print "<a href='#{href}#L#{sl.line_number}' target='_blank'>[#{sl.line_number}]</a>"
      else
        print "[#{sl.line_number}]"
      end
      puts " #{sl.colorize_line}"
      puts "<br>" if ENV['HTML']
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
      spell_check_file file if f.end_with? $ext
    end
  end # foreach dir

end


def main(path)
  $speller = FFI::Aspell::Speller.new('en_US')
  puts "<html><head><title>docker parse</title><head><body>" if ENV['HTML']

  Dir.foreach(path) do |f|
    next if f == '.' || f == '..'
    file = "#{path}/#{f}"
    if File.directory? file
      puts "<h1><font color='blue'>REPO: docker/#{f}</font></h1>" if ENV['HTML']
      $repo = f
      spell_check_dir file
    end
  end # foreach dir

  # spell_check_dir path
  puts "</body></html>" if ENV['HTML']
  $speller.close
end



$root = ENV['SRC']
$ext = ENV['EXT']
$repo = nil

if $root.nil? or $ext.nil?
  puts "hehe"
else
  main $root
end

