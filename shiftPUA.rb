#!/usr/bin/env ruby
require "set"
require "./ruby-utils/getOpts.rb"
require "./ruby-utils/rotator.rb"
require "./sfd.rb"

STDERR.printf("0x%04X\n", Opts.pua_delta)

if (Opts.args.length > 0)
  f = File::open(Opts.args.first, "r")
  sfdFont = SfdFont.new().parse(f)  
  f.close()
else
  sfdFont = SfdFont.new().parse(STDIN)  
end

sfdFont.sfdChars.each do |sc|
  next if (sc.name() !~ /^u[0-9A-F]+$/)
  next if (!sc.isPUA())
  sc.shiftPUA(Opts.pua_delta)
  sc.renameByPUA()
  STDERR.printf("shift PUA: 0x%04X -> 0x%04X\n", sc.attr["Encoding.original"].first, sc.attr["Encoding"].first)
end

puts sfdFont.sfdPreamble.join("\n")

printf("BeginChars: %d %d\n",
  sfdFont.sfdChars.map{|sc| sc.attr["Encoding"].first}.max() + 1,
  sfdFont.sfdChars.length)

sfdFont.sfdChars.each{|sc|
  puts
  puts sc.to_s()
}

puts
puts sfdFont.sfdPostamble.join("\n")
