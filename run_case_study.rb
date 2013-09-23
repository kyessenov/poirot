#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path('../lib', __FILE__)
$LOAD_PATH << File.expand_path('../../alloy_ruby/lib', __FILE__)

require 'sdsl/myutils'

def usage
"""

-------------------------------------------------------------------------
Usage:

  ruby run_case_study.rb <name1>, <name2>, ...
-------------------------------------------------------------------------

"""
end

def fail(msg)
  puts "\nERROR: #{msg}"
  abort
end

def translate_case_study(case_study_name, out_file=nil)
  fail "No case study specified.#{usage}" unless case_study_name

  file_name = case_study_name.
                gsub(/(?<=\w)([A-Z])/, '_\1').
                gsub(/([A-Z])/){|c| c.downcase}
  file_name_no_underscore = file_name.gsub /_/, ""

  patterns = ["lib/seculloy/case_studies/**/#{file_name}.rb",
              "lib/seculloy/case_studies/**/#{file_name_no_underscore}.rb"]
  sources = Dir[*patterns].uniq
  fail "Case study source file not found. Search pattern: #{patterns}" if sources.empty?
  fail "Multiple sources found: #{sources.join('; ')}" if sources.size > 1
  src = sources.first.gsub /^lib\//, ""
  fail "Cannot load `#{src}'" unless require src
  puts "  loaded #{src}"

  view =
    (eval(case_study_name) rescue nil) ||
    (eval("#{case_study_name}Attack") rescue nil)

  fail "Case study view class not found: #{case_study_name}" unless view

  out_file ||= "alloy/#{case_study_name.downcase}.als"

  sdsl_view = view.meta.to_sdsl
  dumpAlloy(sdsl_view, out_file)

  puts "Alloy file saved in #{out_file}"
end

ALL_STUDIES = %w(OAuth OpenId Replay Eavesdropper OpenRedirector CSRF)

if ARGV.empty? || (ARGV.size == 1 && ARGV[0] == "all")
  ALL_STUDIES.each &method(:translate_case_study)
else
  ARGV.each &method(:translate_case_study)
end
