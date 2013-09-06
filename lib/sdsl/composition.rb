# composition.rb
#
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
