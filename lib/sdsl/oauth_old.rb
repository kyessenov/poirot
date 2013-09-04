# oauth.rb
# model of a basic OAuth protocol

require 'view.rb'

resOwner = mod :ResourceOwner do
  stores :authGrants, :Credential, :AuthGrant
  creates :AuthGrant
  exports(:reqAuth, 
          :args => [item(:cred, :Credential)], 
          # must include a valid credential 
          :when => [hasKey(:authGrants, arg(:cred))])
  invokes(:sendResp, 
          :when => [
                    # must be preceded by a successful reqAuth operation
                    triggeredBy(:reqAuth),
                    # must only include auth. grant for given credential
                    :authGrants[trig.cred].eq(o.data)])
end

client = mod :ClientApp do
  stores :cred, :Credential
  creates :Credential
  invokes :reqAuth
  invokes :reqRes
  invokes :reqAccessToken
  exports :sendResp, :args => [set(:data,:Payload)]
end

authServer = mod :AuthorizationServer do
  stores :accessTokens, :AuthGrant, :AccessToken
  creates :AccessToken
  exports(:reqAccessToken, 
          :args => [item(:authGrant, :AuthGrant)], 
          # must include a valid authorization grant
          :when => [hasKey(:accessTokens, o.authGrant)])
  invokes(:sendResp, 
          :when => [
                    # must be preceded by a reqAccessToken op
                    triggeredBy(:reqAccessToken),
                    # must only include access token for given auth grant
                    :accessTokens[trig.authGrant].eq(o.data)])
end

resServer = mod :ResourceServer do
  stores :resources, :AccessToken, :Resource
  creates :Resource
  exports(:reqRes, 
          :args => [item(:accessToken, :AccessToken)],
          # must include a valid access token
          :when => [hasKey(:resources, arg(:accessToken))])
  invokes(:sendResp,
          :when => [
                    # must be preceded by a reqRes op
                    triggeredBy(:reqRes),
                    # must only include resource for given access token
                    :resources[trig.accessToken].eq(o.data)])
end

# data definitions
authGrant = datatype :AuthGrant do extends :Payload end
accessToken = datatype :AccessToken do extends :Payload end
credential = datatype :Credential do extends :Payload end
resource = datatype :Resource do extends :Payload end
otherPayload = datatype :OtherPayload do extends :Payload end
payload = datatype :Payload do setAbstract end

VIEW_OAUTH = view :OAuth do 
  modules resOwner, client, authServer, resServer
  data credential, authGrant, accessToken, resource, otherPayload, payload
  critical resource
  trusted resOwner, client, authServer, resServer
end

drawView VIEW_OAUTH, "oauth.dot"
dumpAlloy VIEW_OAUTH, "oauth.als"

# puts resOwner
# puts client
# puts authServer
# puts resServer

# writeDot mods

