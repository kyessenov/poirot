# composition.rb
#
$LOAD_PATH << File.expand_path('../../../lib', __FILE__)
$SDSL_EXE = 1

require 'sdsl/oauth.rb'
require 'sdsl/attack_open_redirector.rb'
require 'sdsl/attack_csrf.rb'

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
                             :enterCred => :visitB
                           }, 
                           :Invokes => {
                             :sendAuthResp => :httpReq,
                             :reqAuth => :httpReq,
                             :redirect => :httpResp,
                             :enterCred => :visitB
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
                             :enterCred => :visitB
                           }, 
                           :Invokes => {
                             :sendAuthResp => :httpReq,
                             :reqAuth => :httpReq,
                             :redirect => :httpResp,
                             :enterCred => :visitB
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
#                              :httpReqB => :httpReqA,
                              :httpReqB2 => :httpReqA2,
                              :httpRespB => :httpRespA,
                              :visitB => :visitA
                            },
                            :Invokes => {
 #                             :httpReqB => :httpReqA,
                              :httpReqB2 => :httpReqA2,
                              :httpRespB => :httpRespA,
                              :visitB => :visitA
                            },
                            :Data => {
                              
                            }
                            )
drawView mergedClient, "merged_client.dot"
dumpAlloy mergedClient, "merged_client.als"
