# attack_csrf.rb
# model of a cross-site request forgery attack

require 'sdsl/view.rb'

u = mod :User do
  stores set(:intentsA, :URI)
  invokes(:visitA,
          # user only types dest address that he/she intends to visit
          :when => [:intentsA.contains(o.destA)])
end

goodServer = mod :TrustedServer do
  stores :cookies, :Op, :Cookie
  stores :addrA, :Hostname
  stores set(:protected, :Op)
  creates :DOM
  creates :Cookie
  exports(:httpReqA, 
          :args => [item(:cookie, :Cookie), 
                    item(:addrA, :URI)],
          # if op is protected, only accept when it provides a valid cookie
          :when => [implies(:protected.contains(o),
                            o.cookie.eq(:cookies[o]))])
  invokes(:httpRespA,
          :when => [triggeredBy :httpReqA])
end

badServer = mod :MaliciousServer do
  stores :addrA, :Hostname
  creates :DOM   
  exports(:httpReqA2,
          :args => [item(:cookie, :Cookie), 
                    item(:addrA, :URI)])
  invokes(:httpRespA,
          :when => [triggeredBy :httpReqA2])
end

goodClient = mod :Client do
  stores :cookies, :URI, :Cookie
  exports(:visitA,
          :args => [item(:destA, :URI)])
  exports(:httpRespA,
          :args => [item(:dom, :DOM),
                    item(:addrA, :URI)])
  invokes([:httpReqA, :httpReqA2],
          :when => [
                    # req always contains any associated cookie
                    implies(some(:cookies[o.addrA]),
                            o.cookie.eq(:cookies[o.addrA])),
                    disj(
                         # sends a http request only when
                         # the user initiates a connection 
                         conj(triggeredBy(:visitA), 
                              o.addrA.eq(trig.destA)),
                         # or in response to a src tag
                         conjs([triggeredBy(:httpRespA),
                                trig.dom.tags.src.contains(o.addrA)]
                               ))
                   ])
end

dom = datatype :DOM do
  field set(:tags, :HTMLTag)
  extends :Payload
end

addr = datatype :Addr do end

uri = datatype :URI do
  field item(:addr, :Addr)
  field set(:vals, :Payload)
end

imgTag = datatype :ImgTag do 
  field item(:src, :URI)
  extends :HTMLTag
end
tag = datatype :HTMLTag do setAbstract end

cookie = datatype :Cookie do extends :Payload end
otherPayload = datatype :OtherPayload do extends :Payload end
payload = datatype :Payload do setAbstract end

VIEW_CSRF = view :AttackCSRF do
  modules u, goodServer, badServer, goodClient
  trusted goodServer, goodClient, u
  data uri, :Hostname, cookie, otherPayload, payload, dom, tag, imgTag, addr
end

drawView VIEW_CSRF, "csrf.dot"
dumpAlloy VIEW_CSRF, "csrf.als"
# puts goodServer
# puts badServer
# puts goodClient

# writeDot mods

