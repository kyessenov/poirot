# composition.rb
#
require 'oauth.rb'
require 'attack_open_redirector.rb'
require 'attack_csrf.rb'

# Merging OAuth and open redirection threat
mv = composeViews(VIEW_OAUTH, VIEW_OPEN_REDIRECTOR, 
                           :Module => {
                             :ClientServer => :TrustedServer,
                             :AuthorizationServer => :TrustedServer,
                             :UserAgent => :Client,
                             :EndUser => :User
                           },
                          :Exports => {
                             :sendAuthResp => :httpReq,
                             :reqAuth => :httpReq,
                             :redirect => :httpResp,
                             :enterCred => :visit
                           }, 
                           :Invokes => {
                             :sendAuthResp => :httpReq,
                             :reqAuth => :httpReq,
                             :redirect => :httpResp,
                             :enterCred => :visit
                           },
                           :Data => {
                             
                           })
drawView mv, "merged_open_redirect_oauth.dot"
dumpAlloy mv, "merged_open_redirect_oauth.als"

# Merging OAuth and open redirection threat
mv2 = composeViews(VIEW_OAUTH, VIEW_CSRF, 
                           :Module => {
                             :ClientServer => :TrustedServer,
                             :AuthorizationServer => :TrustedServer,
                             :UserAgent => :Client,
                             :EndUser => :User
                           },
                          :Exports => {
                             :sendAuthResp => :httpReq,
                             :reqAuth => :httpReq,
                             :redirect => :httpResp,
                             :enterCred => :visit
                           }, 
                           :Invokes => {
                             :sendAuthResp => :httpReq,
                             :reqAuth => :httpReq,
                             :redirect => :httpResp,
                             :enterCred => :visit
                           },
                           :Data => {
                             
                           })
drawView mv2, "merged_csrf_oauth.dot"
dumpAlloy mv2, "merged_csrf_oauth.als"

mergedClient = composeViews(VIEW_OPEN_REDIRECTOR, VIEW_CSRF,
                            :Module => {
                              :User => :User,
                              :TrustedServer => :TrustedServer,
                              :MaliciousServer => :MaliciousServer,
                              :Client => :Client
                            },
                            :Exports => {
                              :httpReq => :httpReq,
                              :httpReq2 => :httpReq2,
                              :httpResp => :httpResp,
                              :visit => :visit
                            },
                            :Invokes => {
                              :httpReq => :httpReq,
                              :httpReq2 => :httpReq2,
                              :httpResp => :httpResp,
                              :visit => :visit
                            },
                            :Data => {
                            }
                            )
drawView mergedClient, "merged_client.dot"
dumpAlloy mergedClient, "merged_client.als"
