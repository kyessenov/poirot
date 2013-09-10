#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path('../lib', __FILE__)

require 'sdsl/myutils'

def usage
"""

-------------------------------------------------------------------------
Usage:

  ruby run_case_study.rb <name> [out_file]

  where <name> is the name of the case study view class (mandatory)
  (e.g., 'OAuth'), and [out_file] is the output file path (optional).
-------------------------------------------------------------------------

"""
end

def fail(msg)
  puts "\nERROR: #{msg}"
  abort
end

case_study_name = ARGV[0]
fail "No case study specified.#{usage}" unless case_study_name

file_name = case_study_name.gsub(/(?<=\w)([A-Z])/, '_\1').gsub(/([A-Z])/){|c| c.downcase}
pattern = "lib/seculloy/case_studies/**/#{file_name}.rb"
sources = Dir[pattern]
fail "Case study source file not found. Search pattern: #{pattern}" if sources.empty? 
fail "Multiple sources found: #{sources.join('; ')}" if sources.size > 1
src = sources.first.gsub /^lib\//, ""
fail "Cannot load `#{src}'" unless require src
puts "  loaded #{src}"

view = 
  (eval(case_study_name) rescue nil) ||
  (eval("#{case_study_name}Attack") rescue nil)

fail "Case study view class not found: #{case_study_name}" unless view

out_file = ARGV[1] || "alloy/#{case_study_name.downcase}.als"

sdsl_view = view.meta.to_sdsl
dumpAlloy(sdsl_view, out_file)

puts "Alloy file saved in #{out_file}"
