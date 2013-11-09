#!/usr/bin/env ruby

require_relative 'test_helper'

# $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
# $LOAD_PATH.unshift File.expand_path('../../../alloy_ruby/lib', __FILE__)
# $LOAD_PATH.unshift File.expand_path('../../../arby/lib', __FILE__)

require 'sdsl/myutils'

require 'slang/case_studies/area2/area2'
require "slang/case_studies/http/http"
# require "slang/case_studies/paywall/referer_interaction"
# require "slang/case_studies/paywall/cookie_replay"
# require "slang/case_studies/paywall/javascript_hampering"

def dump(view, name, color="beige")
  dumpAlloy(view, "../alloy/#{name}.als")
  drawView(view, "../alloy/#{name}.dot", color)
end

area2_view = eval("Area2").meta.to_sdsl
http_view = eval("HTTP").meta.to_sdsl
# cookie_replay_view = eval("CookieReplay").meta.to_sdsl
# javascript_hampering_view = eval("JavascriptHampering").meta.to_sdsl
# referer_interaction_view = eval("RefererInteraction").meta.to_sdsl

dump(area2_view, "area2")
dump(http_view, "http")
# dump(cookie_replay_view, "cookie_replay")
# dump(javascript_hampering_view, "javascript_hampering")
# dump(referer_interaction_view, "referer_interaction")

# mv = composeViews(http_view, cookie_replay_view)
# mv = composeViews(mv, javascript_hampering_view)
# mv = composeViews(mv, referer_interaction_view)
mv = composeViews(area2_view, http_view, {
                    :Module => {
                      "Admin" => "User",
                      "Faculty" => "User",
                      "Student" => "User",
                      "A2Site" => "Server",
                    },
                    :Exports => {
                    },
                    :Invokes => {
                    },
                    :Data => {
                    }
                  })

dump(mv, "merged")

