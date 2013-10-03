#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../alloy_ruby/lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../arby/lib', __FILE__)

require 'sdsl/myutils'

require 'pry'

require "slang/case_studies/merge_test"

def dump(view, name)
  dumpAlloy(view, "../alloy/#{name}.als")
  drawView(view, "../alloy/#{name}.dot")
end

nyt_view = NYT.meta.to_sdsl
wp_view = WP.meta.to_sdsl

mv = composeViews(nyt_view, wp_view,
                  :Module => {
                   	 "NYTimes" => "WPost",
                  	 "NYTUser" => "WPUser"
                  },
                  :Exports => {
              		"NYTimes__GetArticle"  => "WPost__GetLatestNews",
              		"NYTUser__SendArticle" => "WPUser__SendResp"
                  }, 
                  :Invokes => {
              		"NYTimes__GetArticle"  => "WPost__GetLatestNews",
              		"NYTUser__SendArticle" => "WPUser__SendResp"
                  },
                  :Data => {
                    	"Article"   => "News",
                  })

dump(mv, "merged")

