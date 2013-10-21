#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../alloy_ruby/lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../arby/lib', __FILE__)

require 'sdsl/myutils'

require "slang/case_studies/paywall/paywall"
require "slang/case_studies/paywall/http"
require "slang/case_studies/paywall/referer_interaction"
require "slang/case_studies/paywall/cookie_replay"
require "slang/case_studies/paywall/javascript_hampering"

def dump(view, name, color="beige")
  dumpAlloy(view, "../alloy/#{name}.als")
  drawView(view, "../alloy/#{name}.dot", color)
end

paywall_view = eval("Paywall").meta.to_sdsl
http_view = eval("HTTP").meta.to_sdsl
cookie_replay_view = eval("CookieReplay").meta.to_sdsl
javascript_hampering_view = eval("JavascriptHampering").meta.to_sdsl
referer_interaction_view = eval("RefererInteraction").meta.to_sdsl

dump(paywall_view, "paywall")
dump(http_view, "http")
dump(cookie_replay_view, "cookie_replay")
dump(javascript_hampering_view, "javascript_hampering")
dump(referer_interaction_view, "referer_interaction")

# mv = composeViews(paywall_view, http_view,
#                   :Module => {
#                     "NYTimes" => "Server",
#                     "Browser" => "Client"
#                   },
#                   :Exports => {
#                      "NYTimes__GetArticle" => "Server__SendReq",
#                      "Browser__SendArticle" => "Client__SendResp",
#                     "Server__SendReq" => "NYTimes__GetArticle",
#                     "Client__SendResp" => "Browser__SendArticle"
#                   }, 
#                   :Invokes => {
#                   },
#                   :Data => {
#                     "Article" => "HTML",
#                     "ArticleID" => "Str",
#                     "Number" => "Str"
#                   })

# dump(mv, "merged")
