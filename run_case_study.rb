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

source = "seculloy/case_studies/#{case_study_name.downcase}.rb"
fail "Case study source file not found: #{source}" unless require source

view = eval(case_study_name) rescue nil
fail "Case study view class not found: #{case_study_name}" unless view

out_file = ARGV[1] || "#{case_study_name.downcase}.als"

sdsl_view = view.meta.to_sdsl
dumpAlloy(sdsl_view, out_file)

puts "Alloy file saved in #{out_file}"
