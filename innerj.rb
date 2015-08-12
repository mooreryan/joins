#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

require "trollop"
require "fail_fast"

include FailFast::Assertions

opts = Trollop.options do
  banner <<-EOS

  Do an inner join on the first column of the input files.

  Every file should have a header line. The first column's header
  should be exactly the same in each file.

  Example:
    ruby innerj.rb file1.txt file2.txt file3.txt > joined_file.txt

  Options:
  EOS

  opt(:delimiter, "Field delimiter", type: :string, default: "\t")
end

files = []
headers = []
num_infiles = ARGV.count

ARGV.each do |fname|
  header = {}
  lines = {}
  File.open(fname).each_line.with_index do |line, idx|
    key, *rest = line.chomp.split opts[:delimiter]

    if idx.zero?
      header[key] = rest
      headers << header
    else
      if lines.has_key? key
        abort "key: |#{key}| is repeated in #{fname}"
      end

      lines[key] = rest
    end
  end

  files << lines
end

assert files.count == num_infiles

######################################################################
# print header

header_keys = headers.map { |lines| lines.keys }.flatten.uniq

# ensure header key is the same
assert header_keys.count == 1

header_key  = header_keys.first
header_vals = headers.map { |lines| lines.values }

puts [header_key, header_vals].flatten.join opts[:delimiter]

######################################################################
# print info

# get shared keys
shared_keys = files.map { |lines| lines.keys }.reduce(:&)

shared_keys.each do |key|
  line = [key]
  files.each do |hash|
    line << hash[key]
  end

  puts line.flatten.join opts[:delimiter]
end
