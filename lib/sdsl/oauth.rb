# oauth.rb
# model of a basic OAuth protocol

require 'sdsl/view.rb'

endUser = mod :EndUser do
  stores :cred, :Credential
  creates :Credential  
  exports(:promptForCred,
          :args => [item(:uri, :URI)])
  invokes(:enterCred,
          :when => [triggeredBy(:promptForCred), 
                   o.cred.eq(:cred),
                   o.uri.eq(trig.uri)])
end

userAgent = mod :UserAgent do
  exports(:initFlow,
          :args => [item(:redirectURI, :URI)])
  exports(:enterCred,
          :args => [item(:cred, :Credential), item(:uri, :URI)])
  exports(:redirect,
          :args => [item(:uri, :URI)])
  invokes(:promptForCred, :when => [triggeredBy(:initFlow)])
  invokes(:reqAuth,
          :when => [triggeredBy(:enterCred), 
                    o.cred.eq(trig.cred),
                    o.uri.eq(trig.uri)])
  invokes(:sendAuthResp,
          :when => [triggeredBy(:redirect),
                    o.uri.eq(trig.uri)])
end

client = mod :ClientServer do  
  stores :addr, :Addr
  exports(:sendAuthResp, 
          :args => [item(:uri, :URI)])
  exports(:sendAccessToken,
          :args => [item(:token, :AccessToken)])
  exports(:sendRes,
          :args => [item(:res, :Resource)])
  invokes(:initFlow,
          :when => [o.redirectURI.addr.eq(:addr)])
  invokes :reqRes
  invokes :reqAccessToken
end

authServer = mod :AuthorizationServer do
  stores :authGrants, :Credential, :AuthGrant
  stores :accessTokens, :AuthGrant, :AccessToken
  creates :AuthGrant, :AccessToken
  exports(:reqAuth, 
          :args => [item(:cred, :Credential), item(:uri, :URI)], 
          # must include a valid credential 
          :when => [hasKey(:authGrants, arg(:cred))]) 
  exports(:reqAccessToken, 
          :args => [item(:authGrant, :AuthGrant)], 
          # must include a valid authorization grant
          :when => [hasKey(:accessTokens, o.authGrant)])
  invokes(:redirect,
          :when => [# must be preceded by a reqAuth op
                    triggeredBy(:reqAuth),
                    # only include auth. grant for given cred
                    o.uri.vals.contains(:authGrants[trig.cred]),
                    o.uri.addr.eq(trig.uri.addr)
                   ])
  invokes(:sendAccessToken,
          :when => [# must be preceded by a reqAccessToken op
                    triggeredBy(:reqAccessToken),
                    # only include access token for given auth grant
                    :accessTokens[trig.authGrant].eq(o.token)])
end

resServer = mod :ResourceServer do
  stores :resources, :AccessToken, :Resource
  creates :Resource
  exports(:reqRes, 
          :args => [item(:accessToken, :AccessToken)],
          # must include a valid access token
          :when => [hasKey(:resources, arg(:accessToken))])
  invokes(:sendRes,
          :when => [
                    # must be preceded by a reqRes op
                    triggeredBy(:reqRes),
                    # must only include resource for given access token
                    :resources[trig.accessToken].eq(o.res)])
end

# data definitions
authGrant = datatype :AuthGrant do
  extends :Payload
  setAbstract
end

authCode = datatype :AuthCode do
  extends :AuthGrant
end

addr = datatype :Addr do end

uri = datatype :URI do 
  field item(:addr, :Addr)
  field set(:vals, :Payload)
end

accessToken = datatype :AccessToken do extends :Payload end
credential = datatype :Credential do extends :Payload end
resource = datatype :Resource do extends :Payload end
otherPayload = datatype :OtherPayload do extends :Payload end
payload = datatype :Payload do setAbstract end

VIEW_OAUTH = view :OAuth do 
  modules endUser, userAgent, client, authServer, resServer
  data credential, authGrant, authCode, accessToken
  data uri, addr, resource, otherPayload, payload
  critical resource
  trusted endUser, userAgent, client, authServer, resServer
end

drawView VIEW_OAUTH, "oauth.dot"
dumpAlloy VIEW_OAUTH, "oauth.als"

# puts resOwner
# puts client
# puts authServer
# puts resServer

# writeDot mods
