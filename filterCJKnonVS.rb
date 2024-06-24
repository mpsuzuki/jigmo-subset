#!/usr/bin/env ruby

require "./ruby-utils/getOpts.rb"
require "./ruby-utils/rotator.rb"
require "./sfd.rb"

rot = Rotator.new(1000)

sfdPreamble  = []
sfdChars     = []
sfdPostamble = ["EndChars", "EndSplineFont"]


numCodeSpace = nil
numDefinedChars = nil
STDERR.printf("+")
while (STDIN.gets())
  STDERR.printf(rot.get())
  $_ = $_.chomp()
  if ($_ =~ /BeginChars/)
    numCodeSpace, numDefinedChars, = $_.split(/:\s+/).last.split(/\s+/).map{|t| t.to_i()}
    break;
  end
  
  sfdPreamble << $_
end

while (STDIN.gets())
  $_ = $_.chomp()
  if ($_ =~ /EndChars/)
    break
  elsif ($_ =~ /StartChar/)
    STDERR.printf(rot.get())
    # p sfdChars.last if (0 < sfdChars.length)
    sfdChars.push(SfdChar.new())
  end
  if (0 < sfdChars.length)
    sfdChars.last.append_line($_)
  end
end

ivs2name = Hash.new()
sfdChars.each do |sc|
  next if (!sc.hasAltUni2())
  ivs2name[ sc.attr["AltUni2"].first ] = sc.name()
end

baseInts = ivs2name.keys().map{|t| h = t.split(".").first.hex() }.sort().uniq()
sfdChars_AsBase = sfdChars.select{|sc| baseInts.include?(sc.attr["Encoding"].first)}
sfdChars_AsIVS  = sfdChars.select{|sc| sc.hasAltUni2() && !sfdChars_AsBase.include?(sc)}

sfdChars_subset = sfdChars.select{|sc| sc.isDIGIT()} + sfdChars_AsBase + sfdChars_AsIVS

puts sfdPreamble.join("\n")
printf("BeginChars: %d %d\n", numCodeSpace, sfdChars_subset.length)

sfdChars_subset.each do |sc|
  puts()
  puts sc.to_s()
end

puts()
puts sfdPostamble.join("\n")
