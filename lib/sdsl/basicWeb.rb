
require 'module.rb'

##### instantiation #####

mod :Server do
  exports :HTTPReq
  invokes :HTTPResp
end

mod :Client do
  exports :HTTPResp
  exports :SelectURL
  invokes :HTTPReq
end

mod :User do
  invokes :SelectURL
end

gs = mod :GoodServer do
  extends :Server
  stores(:sessionCookie, :type => "HTTPReq -> Cookie")
end

bs = mod :BadServer do
  extends :Server
end

gc = mod :GoodClient do
  extends :Client
end

gu = mod :GoodUser do
  extends :User
end

puts gs
puts bs
puts gc
puts gu
