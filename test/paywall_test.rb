#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../alloy_ruby/lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../arby/lib', __FILE__)

require 'sdsl/myutils'

require "seculloy/case_studies/paywall/paywall"
require "seculloy/case_studies/paywall/http"
require "seculloy/case_studies/paywall/referer"
require "seculloy/case_studies/paywall/cookie_replay"

def dump(view, name)
  dumpAlloy(view, "../alloy/#{name}.als")
  drawView(view, "../alloy/#{name}.dot")
end

paywall_view = eval("Paywall").meta.to_sdsl
http_view = eval("HTTP").meta.to_sdsl
cookie_replay_view = eval("CookieReplay").meta.to_sdsl

dump(paywall_view, "paywall")
dump(http_view, "http")
dump(cookie_replay_view, "cookie_replay")

# mv = composeViews(paywall_view, http_view,
#                   :Module => {
#                     "NYTimes" => "Server",
#                     "Browser" => "Client"
#                   },
#                   :Exports => {
#                     "NYTimes__GetArticle" => "Server__SendReq",
#                     "Browser__SendArticle" => "Client__SendResp"
#                   }, 
#                   :Invokes => {
#                   },
#                   :Data => {
#                     "Article" => "Str",
#                     "ArticleID" => "Str",
#                     "Number" => "Str"
#                   })

mv = composeViews(paywall_view, cookie_replay_view,
                  :Module => {
                    "NYTimes" => "Server",
                    "Browser" => "Client",
                    "Reader" => "User"
                  },
                  :Exports => {
                    "NYTimes__GetArticle" => "Server__SendReq",
                    "Browser__SendArticle" => "Client__SendResp",
                    "Browser__SelectArticle" => "Client__Visit"
                  }, 
                  :Invokes => {
                  },
                  :Data => {
                    "Article" => "Str",
                    "ArticleID" => "Str",
                    "Number" => "Str"
                  })

dump(mv, "merged")

