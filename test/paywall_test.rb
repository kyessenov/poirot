#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../alloy_ruby/lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../arby/lib', __FILE__)

require 'sdsl/myutils'

require "slang/case_studies/paywall/paywall"
require "slang/case_studies/http/http"
require "slang/case_studies/http/referer_interaction"
require "slang/case_studies/http/cookie_replay"
require "slang/case_studies/http/javascript_hampering"

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

mv = composeViews(http_view, cookie_replay_view)
mv = composeViews(mv, javascript_hampering_view)
mv = composeViews(mv, referer_interaction_view)
mv = composeViews(paywall_view, mv, {
                    # :Module => {
                    #   NYTimes => Server,
                    #   Client => Browser,
                    #   Reader => User
                    # },
                    # :Exports => {
                    #   NYTimes::GetLink => Server::SendReq,
                    #   Client::SendPage => Browser::SendResp,
                    #   Reader::DisplayPage => User::DisplayHTML
                    # },
                    # :Invokes => {
                    #   NYTimes::GetLink => Server::SendReq,
                    #   Client::SendPage => Browser::SendResp,
                    #   Reader::DisplayPage => User::DisplayHTML
                    # },
                    # :Data => {}
                    :Module => {
                      "NYTimes" => "Server",
                      "Client" => "Browser",
                      "Reader" => "User"
                    },
                    :Exports => {
                      "NYTimes__GetLink" => "Server__SendReq",
                      "Client__SendPage" => "Browser__SendResp",
                      "Client__SelectLink" => "Browser__Visit",
                      "Reader__DisplayPage" => "User__DisplayHTML"
                    },
                    :Invokes => {
                      "NYTimes__GetLink" => "Server__SendReq",
                      "Client__SendPage" => "Browser__SendResp",
                      "Client__SelectLink" => "Browser__Visit",
                      "Reader__DisplayPage" => "User__DisplayHTML"
                    },
                    :Data => {
                      "Page" => "HTML"
                    }
                  })

dump(mv, "merged")

