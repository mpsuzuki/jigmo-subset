#!/usr/bin/env ruby

require "set"
require "./ruby-utils/getOpts.rb"

ucsDefined = Set.new()

class UHexRange
  attr_accessor(:base, :delta)

  def initialize()
    @base  = 0
    @delta = 0
  end

  def last()
    return sprintf("U+%04X", base + delta - 1)
  end

  def next_int()
    return (base + delta)
  end

  def next()
    return sprintf("U+%04X", self.next_int())
  end

  def append_or_new(s)
    return self.append_or_new(s.gsub("U+", "").hex())
  end

  def append_or_new_int(i)
    if (self.next_int() == i)
      self.delta += 1
      return self
    else
      r = UHexRange.new()
      r.base  = i
      r.delta = 1
      return r
    end
  end

  def to_s()
    if (@delta > 1)
      return sprintf("U+%04X,%d", @base, @delta)
    else
      return sprintf("U+%04X", @base)
    end
  end
end

while (STDIN.gets())
  next if ($_ !~ /.*platform.*encoding.*format.*language.*/)
  while (STDIN.gets())
    $_ = $_.chomp()
    break if ($_.length == 0)
    ucsDefined << $_.split(/\s*=>\s*/).first.hex()
  end
end

arr = ucsDefined.to_a().sort()

if (Opts.include?("negate"))
  arr = (0...(arr.last)).to_a().select{|a| !ucsDefined.include?(a)}
end

uhexRanges = Array.new()
arr.to_a().sort().each do |i|
  if (uhexRanges.length == 0)
    uhexRanges << UHexRange.new()
    uhexRanges.last.base == i
  else
    r = uhexRanges.last.append_or_new_int(i)
    uhexRanges.push(r) if (r != uhexRanges.last)
  end
end

uhexRanges.each do |r|
  puts r.to_s()
end
