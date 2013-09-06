# attack_open_redirector.rb
# model of an attack that involves an open redirector

require 'sdsl/view.rb'

u = mod :User do
  stores set(:intentsB, :URI)
  invokes(:visit,
          # user only types dest address that he/she intends to visit
          :when => [:intentsB.contains(o.destB)])
  # assumption: the user doesn't type addresses of a malicious site
  assumes(neg(:intentsB.contains(:MaliciousServer.addrB)))
end

gs = mod :TrustedServer do
  stores :addrB, :URI
  # accepts any requests
  exports(:httpReq,
          :args => [item(:addrB, :URI)])
  invokes(:httpResp,
          :when => [triggeredBy(:httpReq)])
end

bs = mod :MaliciousServer do
  stores :addrB, :URI
  exports(:httpReq2, 
          :args => [item(:addrB, :URI)])
  invokes(:httpResp)
end

c = mod :Client do 
  exports(:visit,
          :args => [item(:destB, :URI)])
  # exports responses with redirects
  exports(:httpResp,
          :args => [item(:redirectTo, :URI)])
  # invokes requests with redirects
  invokes([:httpReq, :httpReq2],
          # sends a http request only when
          :when => [disj(
                         # the user initiates a connection or
                         conj(triggeredBy(:visit), o.addrB.eq(trig.destB)),
                         # receives a redirect header from the server
                         conj(triggeredBy(:httpResp),
                              o.addrB.eq(trig.redirectTo)))])
end

VIEW_OPEN_REDIRECTOR = view :OpenRedirector do
  modules u, c, bs, gs
  trusted c, gs, u
  data :URI
end

drawView VIEW_OPEN_REDIRECTOR, "open_redirector.dot"
dumpAlloy VIEW_OPEN_REDIRECTOR, "open_redirector.als"
