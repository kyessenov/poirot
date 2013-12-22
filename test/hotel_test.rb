#!/usr/bin/env ruby

require_relative 'test_helper'

require 'sdsl/myutils'

require 'slang/case_studies/hotel/hotel'

def dump(view, name, color="beige")
  dumpAlloy(view, "../alloy/#{name}.als")
  drawView(view, "../alloy/#{name}.dot", color)
end

hotel_view = HotelLocking.meta.to_sdsl

dump(hotel_view, "hotel")

# mv = composeViews(http_view, cookie_replay_view)
# mv = composeViews(mv, javascript_hampering_view)
# mv = composeViews(mv, referer_interaction_view)
# mv = composeViews(hotel_view, http_view, {
#                     :Module => {
#                       "Admin" => "User",
#                       "Faculty" => "User",
#                       "Student" => "User",
#                       "A2Site" => "Server",
#                     },
#                     :Exports => {
#                     },
#                     :Invokes => {
#                     },
#                     :Data => {
#                     }
#                   })

# dump(mv, "merged")

