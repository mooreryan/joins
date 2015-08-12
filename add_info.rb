#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

require "trollop"
require "fail_fast"

include FailFast::Assertions

opts = Trollop.options do
  banner <<-EOS

  Add info in --info-file to the data in --main-file

  The key column in the --info-file should be unique. The key is the
  first column.

  The values in the key column in the --main-file file can repeat. The
  key can be specified.

  Headers must be present and header for the key must match.

  Options:
  EOS

  opt(:main_file, "Left file", type: :string)
  opt(:info_file, "Info_File file", type: :string)

  opt(:key_main_file, "Key column number for main-file (zero-base)",
      type: :int, default: 0)

  opt(:delimiter, "Field delimiter", type: :string, default: "\t")
  opt(:default_value,
      "Value for when the key doesn't exist in the --info-file",
      type: :string, default: "NA")
end

if opts[:main_file].nil?
  Trollop.die name, "You didn't provide an input file!"
elsif !File.exists?(opts[:main_file])
  Trollop.die name, "#{opts[:main_file]} doesn't exist!"
end

if opts[:info_file].nil?
  Trollop.die name, "You didn't provide an input file!"
elsif !File.exists?(opts[:info_file])
  Trollop.die name, "#{opts[:info_file]} doesn't exist!"
end

info_header = {}
info_file = Hash.new opts[:default_value]
File.open(opts[:info_file]).each_line.with_index do |line, idx|
  key, *rest = line.chomp.split opts[:delimiter]

  if idx.zero?
    info_header[key] = rest
  else
    if info_file.has_key? key
      abort "key: |#{key}| is repeated in #{fname}"
    end

    info_file[key] = rest
  end
end

File.open(opts[:main_file]).each_line.with_index do |line, idx|
  arr = line.chomp.split opts[:delimiter]
  ncols = arr.count
  key = arr[opts[:key_main_file]]

  if idx.zero?
    if info_header.has_key? key
      puts [line.chomp, info_header[key]].join opts[:delimiter]
    else
      abort "Error: keys don't match"
    end
  else

    extra_info = info_file[key]

    puts [arr, extra_info].flatten.compact.join opts[:delimiter]
  end
end
