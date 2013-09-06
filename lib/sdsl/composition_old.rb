# composition.rb
#
require 'sdsl/oauth_old.rb'
require 'sdsl/network.rb'
require 'sdsl/attack_csrf.rb'
require 'sdsl/attack_eavesdropper.rb'
require 'sdsl/attack_open_redirector.rb'
require 'sdsl/attack_replay.rb'

# Composition #1

mergedView = composeViews(VIEW_OAUTH, VIEW_CSRF, 
                          :Module => {
                            :ClientApp => :Client,
                            :AuthorizationServer => :TrustedServer,
                            :ResourceOwner => :TrustedServer,
                            :ResourceServer => :TrustedServer},
                          :Exports => {
                            :reqAccessToken => :httpReq,
                            :reqAuth => :httpReq,
                            :reqRes => :httpReq
                          }, 
                          :Invokes => {
                            :reqAccessToken => :httpReq,
                            :reqAuth => :httpReq,
                            :reqRes => :httpReq
                          },
                          :Data => {
                            :Resource => :Payload
                          })
drawView mergedView, "merged_oauth.dot"
dumpAlloy mergedView, "merged_oauth.als"

mergedView2 = composeViews(VIEW_OAUTH, VIEW_OPEN_REDIRECTOR, 
                           :Module => {
                             :ClientApp => :Client,
                             :AuthorizationServer => :TrustedServer,
                             :ResourceOwner => :TrustedServer,
                             :ResourceServer => :TrustedServer},
                          :Exports => {
                             :reqAccessToken => :httpReq,
                             :sendResp => :httpResp,
                             :reqAuth => :httpReq,
                             :reqRes => :httpReq
                           }, 
                           :Invokes => {
                             :reqAccessToken => :httpReq,
                             :sendResp => :httpResp,
                             :reqAuth => :httpReq,
                             :reqRes => :httpReq
                           },
                           :Data => {
                           })
drawView mergedView2, "merged_open_redirect_oauth.dot"
dumpAlloy mergedView2, "merged_open_redirect_oauth.als"

mergedView3 = composeViews(VIEW_OAUTH, VIEW_REPLAY, 
                           :Module => {
                             :ClientApp => :Endpoint,
                             :AuthorizationServer => :Endpoint,
                             :ResourceOwner => :Endpoint,
                             :ResourceServer => :Endpoint},
                          :Exports => {
                             :reqAccessToken => :deliver,
                             :sendResp => :deliver,
                             :reqAuth => :deliver,
                             :reqRes => :deliver
                           }, 
                           :Invokes => {
                             :reqAccessToken => :deliver,
                             :sendResp => :deliver,
                             :reqAuth => :deliver,
                             :reqRes => :deliver                             
                           },
                           :Data => {
#                             :Resource => :Packet
                           })
drawView mergedView3, "merged_replay_oauth.dot"
dumpAlloy mergedView3, "merged_replay_oauth.als"

# Composition #4
test = composeViews(VIEW_OPEN_REDIRECTOR, VIEW_REPLAY,
                    :Module => {
                      :TrustedServer => :Endpoint,
                      :MaliciousServer => :Endpoint,
                      :Client => :Endpoint
                    },
                    :Exports => {
                      :httpReq => :deliver,
                      :httpResp => :deliver,
                    },
                    :Invokes => {
                      :httpReq => :transmit,
                      :httpResp => :transmit
                    },
                    :Data => {          
                    })
drawView test, "test.dot"
dumpAlloy test, "test.als"

# Composition #4
mergedClient = composeViews(VIEW_OPEN_REDIRECTOR, VIEW_CSRF,
                            :Module => {
                              :User => :User,
                              :TrustedServer => :TrustedServer,
                              :MaliciousServer => :MaliciousServer,
                             :Client => :Client
                            },
                            :Exports => {
                              :httpReq => :httpReq,
                              :httpResp => :httpResp,
                              :visit => :visit
                            },
                            :Invokes => {
                              :httpReq => :httpReq,
                              :httpResp => :httpResp,
                              :visit => :visit
                            },
                            :Data => {
                              :Addr => :URL
                            }
                            )
drawView mergedClient, "merged_client.dot"
dumpAlloy mergedClient, "merged_client.als"

mergedClient_replay = composeViews(mergedClient, VIEW_REPLAY,
                                   :Module => {
                                     :TrustedServer => :Endpoint,
                                     :MaliciousServer => :Endpoint,
                                     :Client => :Endpoint
                                   },
                                   :Exports => {
                                     :httpReq => :deliver,
                                     :httpResp => :deliver,   
                                   },
                                   :Invokes => {
                                     :httpReq => :transmit,
                                     :httpResp => :transmit
                                   },
                                   :Data => {}
                                   )
drawView mergedClient_replay, "merged_client_replay.dot"
dumpAlloy mergedClient_replay, "merged_client_replay.als"

mergedView_final = composeViews(VIEW_OAUTH, mergedClient_replay,
                                :Module => {
                                  :ClientApp => :Client_Endpoint,
                                  :AuthorizationServer => :TrustedServer_Endpoint,
                                  :ResourceOwner => :TrustedServer_Endpoint,
                                  :ResourceServer => :TrustedServer_Endpoint},
                                :Exports => {
                                  :reqAccessToken => :httpReq_deliver,
                                  :sendResp => :httpResp_deliver,
                                  :reqAuth => :httpReq_deliver,
                                  :reqRes => :httpReq_deliver
                                }, 
                                :Invokes => {
                                  :reqAccessToken => :httpReq_transmit,
                                  :sendResp => :httpResp_transmit,
                                  :reqAuth => :httpReq_transmit,
                                  :reqRes => :httpReq_transmit
                                },
                                :Data => {
                                  # :Resource => :Payload
                                })

drawView mergedView_final, "merged_final.dot"
dumpAlloy mergedView_final, "merged_final.als"

# #pp VIEW_OAUTH
# #dumpAlloy VIEW_OAUTH
# #pp VIEW_CSRF
# #dumpAlloy VIEW_CSRF
